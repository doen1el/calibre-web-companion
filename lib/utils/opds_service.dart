import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:logger/web.dart';

class OpdsService {
  final ApiService _apiService = ApiService();
  Logger logger = Logger();

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
