import 'dart:convert';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:logger/web.dart';

class JsonService {
  final ApiService _apiService = ApiService();
  Logger logger = Logger();

  /// Loads a specific book item by its UUID
  ///
  /// Parameters:
  ///
  /// - `bookUuid`: The UUID of the book to fetch
  Future<BookItem> fetchBook({required String bookUuid}) async {
    logger.i('Fetching book - UUID: $bookUuid');

    try {
      final response = await _apiService.get(
        '/ajax/book/$bookUuid',
        AuthMethod.basic,
      );

      // logger.d(response.body);

      if (response.statusCode == 200) {
        BookItem book;

        try {
          // Try parsing the JSON response
          final bookJson = json.decode(response.body);
          book = _parseBookFromJson(bookJson)!;
        } catch (jsonError) {
          // JSON parsing failed, use manual extraction
          logger.w('JSON parsing failed: $jsonError. Using manual extraction.');

          final bookData = _extractBookData(response.body, bookUuid);
          book = _parseBookFromJson(bookData)!;
        }

        // Serieninformationen hinzufügen, wenn nötig
        book = await enhanceBookWithSeriesInfo(book);

        return book;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception while fetching book: $e');
      rethrow;
    }
  }

  /// Fetches a list of books from the server
  ///
  /// Parameters:
  ///
  /// - `offset`: The offset to start fetching books from
  /// - `limit`: The maximum number of books to fetch
  /// - `searchQuery`: An optional search query to filter books
  /// - `sortBy`: The field to sort by
  /// - `sortOrder`: The order to sort by (asc/desc)
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

    // Check if the response contains a 'rows' field
    if (response.containsKey('rows') && response['rows'] is List) {
      final List<dynamic> rows = response['rows'];
      for (var bookData in rows) {
        try {
          // Parse the book data
          final book = _parseBookFromJson(bookData);
          if (book != null) {
            books.add(book);
          }
        } catch (e) {
          logger.e('Error parsing book: $e');
        }
      }
    }

    logger.i('Parsed ${books.length} books');
    return books;
  }

  /// Extracts book data from a raw JSON response
  ///
  /// Parameters:
  ///
  /// - `responseBody`: The raw JSON response body
  /// - `bookUuid`: The UUID of the book
  Map<String, dynamic> _extractBookData(String responseBody, String bookUuid) {
    Map<String, dynamic> result = {'uuid': bookUuid, 'title': 'Unknown Title'};

    try {
      // Extract ID
      final idMatch = RegExp(
        r'"application_id":\s*(\d+)',
      ).firstMatch(responseBody);
      if (idMatch != null) {
        result['id'] = idMatch.group(1);
      }

      // Extract title (with proper unescaping)
      final titleMatch = RegExp(
        r'"title":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
        dotAll: true,
      ).firstMatch(responseBody);
      if (titleMatch != null) {
        String title = titleMatch.group(1)!;
        title = title.replaceAll('"', '');
        result['title'] = title;
      }

      // Extract author
      final authorsSection = _extractSection(responseBody, 'authors');
      if (authorsSection != null) {
        final authors = _extractStringArray(authorsSection);
        if (authors.isNotEmpty) {
          result['author'] = authors.join(', ');
        }
      }

      // Extract categories (tags)
      final tagsSection = _extractSection(responseBody, 'tags');
      if (tagsSection != null) {
        final tags = _extractStringArray(tagsSection);
        if (tags.isNotEmpty) {
          result['tags'] = tags;
        }
      }

      // Extract rating
      final ratingMatch = RegExp(
        r'"rating":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (ratingMatch != null) {
        result['ratings'] = ratingMatch.group(1);
      }

      // Extract if the book has a cover
      result['has_cover'] = true;

      // Extract series if available
      final seriesMatch = RegExp(
        r'"series":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (seriesMatch != null) {
        result['series'] = seriesMatch.group(1);
      } else {
        result['series'] = '';
      }

      // Extract summary
      try {
        final commentsMatch = RegExp(
          r'"comments":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
          dotAll: true,
        ).firstMatch(responseBody);
        if (commentsMatch != null) {
          String comments = commentsMatch.group(1)!;
          comments = comments.replaceAll(RegExp(r'<[^>]*>'), '');
          result['comments'] = comments;
        } else {
          result['comments'] = '';
        }
      } catch (e) {
        logger.w('Failed to extract comments: $e');
        result['comments'] = '';
      }

      // Extract published date
      final publisherMatch = RegExp(
        r'"publisher":\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (publisherMatch != null) {
        result['publisher'] = publisherMatch.group(1);
      }

      // Extract language
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

  /// Extract a section of JSON data based on a field name
  ///
  /// Parameters:
  ///
  /// - `json`: The JSON data to extract from
  /// - `fieldName`: The name of the field to extract
  String? _extractSection(String json, String fieldName) {
    final regex = RegExp('"$fieldName":\\s*(\\[.*?\\])', dotAll: true);
    final match = regex.firstMatch(json);
    return match?.group(1);
  }

  /// Extracts an array of strings from a JSON array
  ///
  /// Parameters:
  ///
  /// - `arrayText`: The JSON array text to extract from
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

  /// Parses a book item from a JSON map
  ///
  /// Parameters:
  ///
  /// - `bookData`: The JSON map containing the book data
  BookItem? _parseBookFromJson(Map<String, dynamic> bookData) {
    try {
      // Extract ID and UUID
      final id =
          bookData['application_id']?.toString() ??
          bookData['id']?.toString() ??
          '';
      final uuid = bookData['uuid']?.toString() ?? '';

      // Extract title, safely handling quotes
      final title = bookData['title'] ?? 'Unknown Title';

      // Extract author information
      String author = '';
      if (bookData['authors'] is List) {
        author = (bookData['authors'] as List).join(', ');
      } else {
        author =
            bookData['author_name'] ??
            bookData['author'] ??
            bookData['authors'] ??
            '';
      }

      // Extract publisher
      final publisher =
          bookData['publisher_name'] ??
          bookData['publisher'] ??
          bookData['publishers'] ??
          '';

      // Extract language from array or string
      String language = '';
      if (bookData['languages'] is List &&
          (bookData['languages'] as List).isNotEmpty) {
        language = (bookData['languages'] as List).first.toString();
      } else {
        language =
            bookData['language_name'] ??
            bookData['language'] ??
            bookData['languages'] ??
            '';
      }

      // Extract summary, removing HTML tags if present
      String summary =
          bookData['description'] ??
          bookData['comment'] ??
          bookData['comments'] ??
          '';

      if (summary.contains('<')) {
        summary =
            summary
                .replaceAll(RegExp(r'<p[^>]*>'), '\n\n')
                .replaceAll(RegExp(r'</p>'), '')
                .replaceAll(RegExp(r'<br[^>]*>'), '\n')
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll(RegExp(r'\s{2,}'), ' ')
                .trim();
      }

      // Extract dates
      DateTime updated;
      try {
        updated = DateTime.parse(
          bookData['last_modified'] ??
              bookData['timestamp'] ??
              bookData['atom_timestamp'] ??
              '',
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

      double? seriesIndex;

      if (bookData['series_index'] != null) {
        try {
          seriesIndex = double.parse(bookData['series_index'].toString());
        } catch (e) {
          logger.e("Failed to parse series index: $e");
        }
      }

      logger.d('Series index: $seriesIndex');

      // Extract categories (tags)
      List<String> categories = [];
      if (bookData['tags'] is List) {
        categories =
            (bookData['tags'] as List)
                .map((tag) => tag.toString().trim())
                .where((tag) => tag.isNotEmpty)
                .toList();
      } else if (bookData['tags'] is String) {
        final tagsStr = bookData['tags'].toString();
        if (tagsStr.isNotEmpty) {
          categories = tagsStr.split(',').map((tag) => tag.trim()).toList();
        }
      } else if (bookData['tag'] is String) {
        categories = [bookData['tag']];
      }

      // Extract file formats and size
      int? fileSize;
      List<String> formats = [];
      Map<String, String> downloadLinks = {};

      // Extract formats list
      if (bookData['formats'] is List) {
        formats =
            (bookData['formats'] as List)
                .map((format) => format.toString())
                .toList();
      }

      // Extract file size from format_metadata if available
      if (bookData['format_metadata'] is Map) {
        final formatMetadata = bookData['format_metadata'] as Map;
        if (formats.isNotEmpty && formatMetadata.containsKey(formats.first)) {
          final firstFormat = formatMetadata[formats.first];
          if (firstFormat is Map && firstFormat.containsKey('size')) {
            fileSize = int.tryParse(firstFormat['size'].toString());
          }
        }
      }

      // Extract main format download link
      if (bookData['main_format'] is Map) {
        final mainFormat = bookData['main_format'] as Map;
        mainFormat.forEach((key, value) {
          downloadLinks[key.toString().toLowerCase()] = value.toString();
        });
      }

      // Extract other formats download links
      if (bookData['other_formats'] is Map) {
        final otherFormats = bookData['other_formats'] as Map;
        otherFormats.forEach((key, value) {
          downloadLinks[key.toString().toLowerCase()] = value.toString();
        });
      }

      // Extract rating
      double? rating;
      if (bookData['rating'] != null) {
        try {
          rating = double.parse(bookData['rating'].toString());
        } catch (e) {
          // Failed to parse rating
        }
      }

      String coverUrl = bookData['cover']?.toString() ?? '';
      String thumbnailUrl = bookData['thumbnail']?.toString() ?? '';

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
        seriesIndex: seriesIndex,
        formats: formats,
        downloadLinks: downloadLinks,
        rating: rating,
        coverUrl: coverUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      logger.e('Error in _parseBookFromJson: $e');
      return null;
    }
  }

  // Neue Methode hinzufügen, um Serieninformationen aus HTML zu extrahieren
  /// Holt Serieninformationen für ein Buch aus der HTML-Seite
  ///
  /// Parameters:
  ///
  /// - `bookId`: Die ID des Buchs
  /// Holt nur den Seriennamen aus der HTML-Seite
  ///
  /// Parameters:
  ///
  /// - `bookId`: Die ID des Buchs
  Future<String> fetchSeriesInfoFromHtml(String bookId) async {
    logger.i('Fetching series info from HTML for book ID: $bookId');

    try {
      final response = await _apiService.get(
        '/book/$bookId',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        final html = response.body;

        // Find the series link using string methods
        final String seriesPrefix = '/series/stored/';
        final int seriesIndex = html.indexOf(seriesPrefix);

        if (seriesIndex != -1) {
          // Log the context for debugging
          final start = seriesIndex - 50 > 0 ? seriesIndex - 50 : 0;
          final end =
              seriesIndex + 150 < html.length ? seriesIndex + 150 : html.length;
          final context = html.substring(start, end);
          logger.d('Context around series mention: $context');

          // Find the closing position of the href attribute
          final int hrefEnd = html.indexOf('>', seriesIndex);
          if (hrefEnd != -1) {
            // Find the closing tag after the href
            final int closingTag = html.indexOf('</a>', hrefEnd);
            if (closingTag != -1) {
              // Extract the series name (text between > and </a>)
              final String seriesName =
                  html.substring(hrefEnd + 1, closingTag).trim();
              logger.i('Found series info in HTML: $seriesName');
              return seriesName;
            }
          }
        }

        logger.i('No series information found in HTML');
      } else {
        logger.w('Error fetching book page: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching series info from HTML: $e');
    }

    return '';
  }

  /// Extend a book object with series information if available
  ///
  /// Parameters:
  ///
  /// - `book`: The book object to enhance
  Future<BookItem> enhanceBookWithSeriesInfo(BookItem book) async {
    if ((book.series == null || book.series!.isEmpty) && book.id.isNotEmpty) {
      final seriesName = await fetchSeriesInfoFromHtml(book.id);

      if (seriesName != '') {
        return BookItem(
          id: book.id,
          title: book.title,
          author: book.author,
          uuid: book.uuid,
          publisher: book.publisher,
          updated: book.updated,
          published: book.published,
          language: book.language,
          categories: book.categories,
          summary: book.summary,
          fileSize: book.fileSize,
          series: seriesName,
          seriesIndex: book.seriesIndex,
          formats: book.formats,
          downloadLinks: book.downloadLinks,
          rating: book.rating,
          coverUrl: book.coverUrl,
          thumbnailUrl: book.thumbnailUrl,
        );
      }
    }

    return book;
  }
}
