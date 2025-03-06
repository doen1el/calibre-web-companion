import 'dart:convert';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/views/book_list.dart';
import 'package:logger/web.dart';

class OpdsService {
  final ApiService _apiService = ApiService();
  Logger logger = Logger();

  /// Lädt ein einzelnes Buch anhand seiner UUID
  Future<BookItem> fetchBook({required String bookUuid}) async {
    logger.i('Fetching book - UUID: $bookUuid');

    try {
      final response = await _apiService.get(
        '/ajax/book/$bookUuid',
        AuthMethod.basic, // Cookie auth, da es über die Web-UI geht
      );

      if (response.statusCode == 200) {
        try {
          // Versuche direktes Parsen für den Fall, dass es valides JSON ist
          final bookJson = json.decode(response.body);
          return _parseBookFromJson(bookJson)!;
        } catch (jsonError) {
          // Bei Parsing-Fehlern verwende den manuellen Extraktionsansatz
          logger.w('JSON parsing failed: $jsonError. Using manual extraction.');

          // Extrahiere Daten manuell mit einem sicheren Ansatz
          final bookData = _extractBookData(response.body, bookUuid);
          return _parseBookFromJson(bookData)!;
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception while fetching book: $e');
      rethrow;
    }
  }

  // Sichererer Ansatz zum Extrahieren von Buchdaten aus fehlerhaftem JSON
  Map<String, dynamic> _extractBookData(String responseBody, String bookUuid) {
    Map<String, dynamic> result = {'uuid': bookUuid, 'title': 'Unknown Title'};

    try {
      // Extrahiere ID
      final idMatch = RegExp(
        r'"application_id":\s*(\d+)',
      ).firstMatch(responseBody);
      if (idMatch != null) {
        result['id'] = idMatch.group(1);
      }

      // Extrahiere Titel (unter Berücksichtigung problematischer Anführungszeichen)
      final titleMatch = RegExp(
        r'"title":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
        dotAll: true,
      ).firstMatch(responseBody);
      if (titleMatch != null) {
        String title = titleMatch.group(1)!;
        title = title.replaceAll('"', '');
        result['title'] = title;
      }

      // Extrahiere Autoren
      final authorsSection = _extractSection(responseBody, 'authors');
      if (authorsSection != null) {
        final authors = _extractStringArray(authorsSection);
        if (authors.isNotEmpty) {
          result['author'] = authors.join(
            ', ',
          ); // Für BookItem verwenden wir author als String
        }
      }

      // Extrahiere Tags/Kategorien
      final tagsSection = _extractSection(responseBody, 'tags');
      if (tagsSection != null) {
        final tags = _extractStringArray(tagsSection);
        if (tags.isNotEmpty) {
          result['tags'] = tags; // Wird im Parser zu categories
        }
      }

      // Extrahiere Wertung
      final ratingMatch = RegExp(
        r'"rating":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (ratingMatch != null) {
        result['ratings'] = ratingMatch.group(1);
      }

      // Extrahiere has_cover
      result['has_cover'] = true;

      // Extrahiere Series wenn vorhanden
      final seriesMatch = RegExp(
        r'"series":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (seriesMatch != null) {
        result['series'] = seriesMatch.group(1);
      } else {
        result['series'] = '';
      }

      // Extrahiere Zusammenfassung/Kommentar
      try {
        final commentsMatch = RegExp(
          r'"comments":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
          dotAll: true,
        ).firstMatch(responseBody);
        if (commentsMatch != null) {
          String comments = commentsMatch.group(1)!;
          // HTML entfernen
          comments = comments.replaceAll(RegExp(r'<[^>]*>'), '');
          result['comments'] = comments; // Wird zu summary
        } else {
          result['comments'] = '';
        }
      } catch (e) {
        logger.w('Failed to extract comments: $e');
        result['comments'] = '';
      }

      // Extrahiere Verlag
      final publisherMatch = RegExp(
        r'"publisher":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (publisherMatch != null) {
        result['publisher'] = publisherMatch.group(1);
      }

      // Extrahiere Sprache
      final languageMatch = RegExp(
        r'"languages":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (languageMatch != null) {
        result['languages'] = languageMatch.group(1);
      }
    } catch (e) {
      logger.e('Error during manual data extraction: $e');
    }

    return result;
  }

  // Hilfsmethode zum Extrahieren eines Abschnitts des JSON zwischen Feldname und nächstem Feld
  String? _extractSection(String json, String fieldName) {
    final regex = RegExp('"$fieldName":\\s*(\\[.*?\\])', dotAll: true);
    final match = regex.firstMatch(json);
    return match?.group(1);
  }

  // Hilfsmethode zum Extrahieren von String-Array-Werten
  List<String> _extractStringArray(String arrayText) {
    List<String> result = [];
    // Einfacher aber effektiver Ansatz für wohlgeformte Teile
    final matches = RegExp(r'"([^"]+)"').allMatches(arrayText);
    for (var match in matches) {
      if (match.groupCount >= 1) {
        result.add(match.group(1)!);
      }
    }
    return result;
  }

  Future<List<BookItem>> fetchBooks({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    String sortBy = 'title',
    String sortOrder = 'asc',
  }) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      'sort': sortBy,
      'order': sortOrder,
    };

    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    final response = await _apiService.getJson(
      '/ajax/listbooks',
      AuthMethod.cookie,
      queryParams: queryParams,
    );

    List<BookItem> books = [];

    // Prüfe auf das erwartete Format mit 'rows'
    if (response.containsKey('rows') && response['rows'] is List) {
      final List<dynamic> rows = response['rows'];
      for (var bookData in rows) {
        try {
          // Konvertiere die Daten in ein BookItem
          final book = _parseBookFromJson(bookData);
          if (book != null) {
            books.add(book);
          }
        } catch (e) {
          print('Error parsing book: $e');
          // Fahre mit dem nächsten Buch fort
        }
      }
    }

    print('Parsed ${books.length} books');
    return books;
  }

  /// Konvertiert JSON-Daten aus der /ajax/listbooks API in ein BookItem
  /// Konvertiert JSON-Daten aus der /ajax/listbooks API in ein BookItem
  BookItem? _parseBookFromJson(Map<String, dynamic> bookData) {
    try {
      // Extrahiere ID und UUID
      final id = bookData['id']?.toString() ?? '';
      final uuid = bookData['uuid']?.toString() ?? '';

      // Extrahiere einfache Textfelder
      final title = bookData['title'] ?? 'Unknown Title';

      // Prüfe verschiedene mögliche Autor-Felder
      final author =
          bookData['author_name'] ??
          bookData['author'] ??
          bookData['authors'] ?? // Neues Feld hinzugefügt
          '';

      final publisher =
          bookData['publisher_name'] ??
          bookData['publisher'] ??
          bookData['publishers'] ?? // Neues Feld hinzugefügt
          '';

      final language =
          bookData['language_name'] ??
          bookData['language'] ??
          bookData['languages'] ?? // Neues Feld hinzugefügt
          '';

      final summary =
          bookData['description'] ??
          bookData['comment'] ??
          bookData['comments'] ?? // Neues Feld hinzugefügt
          '';

      // Extrahiere Datumswerte
      DateTime updated;
      try {
        updated = DateTime.parse(
          bookData['last_modified'] ??
              bookData['timestamp'] ??
              bookData['atom_timestamp'] ??
              '', // Neues Feld hinzugefügt
        );
      } catch (e) {
        updated = DateTime.now();
      }

      DateTime? published;
      try {
        if (bookData['pubdate'] != null &&
            bookData['pubdate'].toString().isNotEmpty) {
          published = DateTime.parse(bookData['pubdate']);
        }
      } catch (e) {
        published = null;
      }

      // Extrahiere Tags/Kategorien
      List<String> categories = [];
      if (bookData['tags'] is List) {
        categories =
            (bookData['tags'] as List).map((tag) => tag.toString()).toList();
      } else if (bookData['tags'] is String) {
        // Tags können auch als Komma-separierter String kommen
        final tagsStr = bookData['tags'].toString();
        if (tagsStr.isNotEmpty) {
          categories = tagsStr.split(',').map((tag) => tag.trim()).toList();
        }
      } else if (bookData['tag'] is String) {
        categories = [bookData['tag']];
      }

      // Dateigröße extrahieren (wenn vorhanden)
      int? fileSize;
      if (bookData['size'] != null) {
        try {
          fileSize = int.parse(bookData['size'].toString());
        } catch (e) {
          // Ignoriere Fehler bei der Konvertierung
        }
      }

      return BookItem(
        id: id,
        title: title,
        author: author,
        uuid: uuid,
        publisher: publisher,
        updated: updated,
        published: published,
        language: language,
        categories: categories,
        summary: summary,
        fileSize: fileSize,
      );
    } catch (e) {
      print('Error in _parseBookFromJson: $e');
      return null;
    }
  }

  Future<OpdsFeed<BookItem>> getBookFeed(
    BookListType type, {
    String? subPath,
  }) async {
    final endpoint =
        subPath != null
            ? '${_getEndpointForBookListType(type)}/$subPath'
            : _getEndpointForBookListType(type);

    final xmlAsJson = await _apiService.getXmlAsJson(
      endpoint,
      AuthMethod.basic,
    );

    final feed = xmlAsJson['feed'];

    List<BookItem> books = [];
    if (feed['entry'] != null) {
      if (feed['entry'] is List) {
        books =
            (feed['entry'] as List)
                .map((entry) => _parseBookEntry(entry))
                .whereType<BookItem>()
                .toList();
      } else {
        final book = _parseBookEntry(feed['entry']);
        if (book != null) books.add(book);
      }
    }

    return OpdsFeed<BookItem>(
      items: books,
      title: feed['title'] ?? type.toString(),
      id: feed['id'] ?? '',
    );
  }

  Future<OpdsFeed<CategoryItem>> getCategoryFeed(
    CategoryType type, {
    String? subPath,
  }) async {
    final endpoint =
        subPath != null
            ? '${_getEndpointForCategoryType(type)}/$subPath'
            : _getEndpointForCategoryType(type);
    final xmlAsJson = await _apiService.getXmlAsJson(
      endpoint,
      AuthMethod.basic,
    );

    final feed = xmlAsJson['feed'];

    List<CategoryItem> categories = [];
    if (feed['entry'] != null) {
      if (feed['entry'] is List) {
        categories =
            (feed['entry'] as List)
                .map((entry) => CategoryItem.fromOpdsEntry(entry))
                .toList();
      } else {
        categories = [CategoryItem.fromOpdsEntry(feed['entry'])];
      }
    }

    return OpdsFeed<CategoryItem>(
      items: categories,
      title: feed['title'] ?? type.toString(),
      id: feed['id'] ?? '',
    );
  }

  BookItem? _parseBookEntry(Map<String, dynamic> entry) {
    String entryString = entry.toString();
    int? fileSize;
    String bookId = '';

    RegExp coverRegex = RegExp(r'/opds/cover/(\d+)');
    var coverMatches = coverRegex.allMatches(entryString);
    if (coverMatches.isNotEmpty) {
      bookId = coverMatches.first.group(1)!;
    } else {
      // Suche nach Download-Link-Muster
      RegExp downloadRegex = RegExp(r'/opds/download/(\d+)/');
      var downloadMatches = downloadRegex.allMatches(entryString);
      if (downloadMatches.isNotEmpty) {
        bookId = downloadMatches.first.group(1)!;
      }
    }
    // Extrahiere UUID (aus ID-Feld)
    final String rawId = entry['id'] ?? '';
    final String uuid = rawId.replaceAll('urn:uuid:', '');

    // Fallback für ID, wenn keine numerische ID gefunden wurde
    if (bookId.isEmpty) {
      bookId = uuid; // Verwende UUID als Fallback
    }

    // Rest der Methode wie bisher
    String author = '';
    if (entry['author'] != null) {
      if (entry['author'] is Map) {
        author = entry['author']['name'] ?? '';
      } else if (entry['author'] is List) {
        author = (entry['author'] as List).map((a) => a['name']).join(', ');
      }
    }

    List<String> categories = [];
    if (entry['category'] != null) {
      if (entry['category'] is List) {
        categories =
            (entry['category'] as List)
                .map((c) => c['@label']?.toString() ?? '')
                .where((c) => c.isNotEmpty)
                .toList();
      } else if (entry['category'] is Map) {
        final label = entry['category']['@label']?.toString();
        if (label != null && label.isNotEmpty) {
          categories = [label];
        }
      }
    }

    try {
      return BookItem(
        id: bookId,
        title: entry['title'] ?? 'Unknown Title',
        author: author,
        uuid: uuid,
        publisher: entry['publisher']?['name'],
        updated: DateTime.parse(
          entry['updated'] ?? DateTime.now().toIso8601String(),
        ),
        published:
            entry['published'] != null
                ? DateTime.parse(entry['published'])
                : null,
        language: entry['dcterms:language'],
        categories: categories,
        summary: entry['summary'],
        fileSize: fileSize,
      );
    } catch (e) {
      return BookItem(
        id:
            bookId.isEmpty
                ? DateTime.now().millisecondsSinceEpoch.toString()
                : bookId,
        uuid: uuid,
        title: entry['title'] ?? 'Unbekannter Titel',
        author: author,
        updated: DateTime.now(),
        categories: [],
      );
    }
  }

  String _getEndpointForBookListType(BookListType type) {
    switch (type) {
      case BookListType.readbooks:
        return '/opds/readbooks';
      case BookListType.unreadbooks:
        return '/opds/unreadbooks';
      case BookListType.hot:
        return '/opds/hot';
      case BookListType.newlyAdded:
        return '/opds/new';
      case BookListType.rated:
        return '/opds/rated';
      case BookListType.bookmarked:
        return '/opds/bookmarks';
      case BookListType.discover:
        return '/opds/discover';
    }
  }

  String _getEndpointForCategoryType(CategoryType type, {String? subPath}) {
    String baseEndpoint;
    switch (type) {
      case CategoryType.author:
        baseEndpoint = '/opds/author';
        break;
      case CategoryType.publisher:
        baseEndpoint = '/opds/publisher';
        break;
      case CategoryType.language:
        baseEndpoint = '/opds/language';
        break;
      case CategoryType.category:
        baseEndpoint = '/opds/category';
        break;
      case CategoryType.ratings:
        baseEndpoint = '/opds/ratings';
        break;
      case CategoryType.formats:
        baseEndpoint = '/opds/formats';
        break;
      case CategoryType.series:
        baseEndpoint = '/opds/series';
        break;
    }

    if (subPath != null && subPath.isNotEmpty) {
      return '$baseEndpoint/$subPath';
    }

    return baseEndpoint;
  }

  /// Lädt Bücher direkt von einem vollständigen OPDS-Pfad
  Future<OpdsFeed<BookItem>> getBooksFromPath(String fullPath) async {
    final xmlAsJson = await _apiService.getXmlAsJson(
      fullPath,
      AuthMethod.basic,
    );

    final feed = xmlAsJson['feed'];

    List<BookItem> books = [];
    if (feed['entry'] != null) {
      if (feed['entry'] is List) {
        books =
            (feed['entry'] as List)
                .map((entry) => _parseBookEntry(entry))
                .whereType<BookItem>()
                .toList();
      } else {
        final book = _parseBookEntry(feed['entry']);
        if (book != null) books.add(book);
      }
    }

    return OpdsFeed<BookItem>(
      items: books,
      title: feed['title'] ?? 'Books',
      id: feed['id'] ?? '',
    );
  }
}
