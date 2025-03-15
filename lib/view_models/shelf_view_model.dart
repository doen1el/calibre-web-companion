import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;

class ShelfViewModel extends ChangeNotifier {
  ApiService apiService = ApiService();
  Logger logger = Logger();

  List<ShelfModel> _shelves = [];
  bool _isLoading = false;

  List<ShelfModel> get shelves => _shelves;
  bool get isLoading => _isLoading;

  ShelfDetailModel? _currentShelf;
  ShelfDetailModel? get currentShelf => _currentShelf;

  final Map<String, ShelfDetailModel> _shelfCache = {};

  /// Load shelfs from the server
  Future<void> loadShelfs() async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await apiService.getXmlAsJson(
        '/opds/shelfindex',
        AuthMethod.basic,
      );

      logger.d("API response structure: ${res.runtimeType}");
      logger.d("Feed structure: ${res['feed'].runtimeType}");
      logger.d("Entry structure: ${res['feed']['entry']?.runtimeType}");

      _shelves = ShelfModel.fromFeedJson(res);

      logger.i("Successfully loaded ${_shelves.length} shelves");
    } catch (e, stack) {
      logger.e("Error loading shelves: $e");
      logger.d("Stack trace: $stack");
      _shelves = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a book to a shelf
  ///
  /// Parameters:
  ///
  /// - `shelfId`: The ID of the shelf
  /// - `bookId`: The ID of the book
  Future<bool> addToShelf(String shelfId, String bookId) async {
    try {
      _isLoading = true;
      notifyListeners();
      logger.i('Starting adding to shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return false;
      }

      final path = '/shelf/add/$shelfId/$bookId';

      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && (response.statusCode == 204)) {
        _shelfCache.remove(shelfId);
        logger.i('Successfully added to shelf');
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to add to shelf: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error adding to shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove a book from a shelf
  ///
  /// Parameters:
  ///
  /// - `shelfId`: The ID of the shelf
  /// - `bookId`: The ID of the book
  Future<bool> removeFromShelf(String shelfId, String bookId) async {
    try {
      _isLoading = true;
      notifyListeners();
      logger.i('Starting removing from shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return false;
      }

      final path = '/shelf/remove/$shelfId/$bookId';

      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && (response.statusCode == 204)) {
        _shelfCache.remove(shelfId);
        logger.i('Successfully removing from shelf');
        getShelf(shelfId);
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to remove from shelf: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error removing from shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new shelf
  ///
  /// Parameters:
  ///
  /// - `shelfName`: The name of the new shelf
  Future<bool> createShelf(String shelfName) async {
    try {
      logger.i('Starting creating shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return false;
      }

      final path = '/shelf/create';

      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
        additionalFormData: {'title': shelfName},
      );

      if (response != null && response.statusCode == 302) {
        logger.i('Successfully created shelf');

        await loadShelfs();

        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to create shelf: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error creatig shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Edit an existing shelf
  ///
  /// Parameters:
  ///
  /// - `shelfId`: The ID of the shelf
  /// - `newShelfName`: The new name of the shelf
  Future<bool> editShelf(String shelfId, String newShelfName) async {
    try {
      logger.i('Starting editing shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return false;
      }

      final path = '/shelf/edit/$shelfId';

      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
        additionalFormData: {'title': newShelfName},
      );

      if (response != null && response.statusCode == 302) {
        logger.i('Successfully edited shelf');

        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to edit shelf: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error editing shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Delete a shelf
  ///
  /// Parameters:
  ///
  /// - `shelfId`: The ID of the shelf
  Future<bool> deleteShelf(String shelfId) async {
    try {
      logger.i('Starting deleting shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return false;
      }

      final path = '/shelf/delete/$shelfId';

      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 302) {
        logger.i('Successfully deleted shelf');

        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to delete shelf: $statusCode');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Get detailed information about a shelf
  ///
  /// Parameters:
  ///
  /// - `shelfId`: The ID of the shelf
  Future<ShelfDetailModel?> getShelf(String shelfId) async {
    try {
      logger.i('Starting getting shelf');
      _isLoading = true;
      notifyListeners();

      final baseUrl = await getBaseUrl();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return null;
      }

      final path = '/shelf/$shelfId';

      final response = await apiService.get(path, AuthMethod.cookie);

      if (response.statusCode == 200) {
        logger.i('Successfully got shelf');

        logger.d(response.body);

        _currentShelf = parseShelfHtml(response.body);
        return _currentShelf;
      } else {
        logger.e('Failed to get shelf: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error getting shelf: $e');
      logger.d('Stack trace: $stackTrace');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open book details page
  ///
  /// Parameters:
  ///
  /// - `bookAuthors`: List of authors of the book
  /// - `bookTitle`: Title of the book
  Future<String> openBookDetails(
    List<BookAuthor> bookAuthors,
    String bookTitle,
  ) async {
    JsonService jsonService = JsonService();
    logger.i(
      'Opening book details: $bookTitle by ${bookAuthors.map((e) => e.name).join(' ')}',
    );

    try {
      final res = await jsonService.fetchBooks(searchQuery: bookTitle);

      logger.d('UUID: ${res.first}');

      return res.first.uuid;
    } catch (e) {
      logger.e('Error searching books: $e');

      return '';
    }
  }

  Future<List<ShelfModel>> findShelvesContainingBook(String bookId) async {
    try {
      logger.i('Checking which shelves contain book $bookId');
      if (_shelves.isEmpty) {
        await loadShelfs();
      }

      List<ShelfModel> containingShelves = [];

      for (var shelf in _shelves) {
        ShelfDetailModel? shelfDetails = _shelfCache[shelf.id];

        if (shelfDetails == null) {
          shelfDetails = await getShelf(shelf.id);
          if (shelfDetails != null) {
            _shelfCache[shelf.id] = shelfDetails;
          }
        }

        if (shelfDetails != null) {
          bool containsBook = shelfDetails.books.any(
            (book) => book.id == bookId,
          );
          if (containsBook) {
            containingShelves.add(shelf);
          }
        }
      }

      return containingShelves;
    } catch (e, stackTrace) {
      logger.e('Error checking shelves for book: $e');
      logger.d('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get base URL from shared preferences
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? '';
  }

  /// Get stored session cookie from shared preferences
  Future<String> getStoredCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('calibre_web_session') ?? '';
  }

  /// Extracts CSRF token from HTML content
  ///
  /// Parameters:
  ///
  /// - `htmlBody`: The HTML content of the response
  /// - `logger`: The logger instance
  String? extractCsrfToken(String htmlBody, Logger logger) {
    // Try input field pattern first
    final csrfRegex = RegExp(
      r'<input[^>]*name="csrf_token"[^>]*value="([^"]+)"',
    );
    final csrfMatch = csrfRegex.firstMatch(htmlBody);

    if (csrfMatch != null && csrfMatch.groupCount >= 1) {
      final token = csrfMatch.group(1);
      logger.i('Extracted CSRF token from input field: $token');
      return token;
    }

    // Try meta tag pattern
    final metaRegex = RegExp(
      r'<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"',
    );
    final metaMatch = metaRegex.firstMatch(htmlBody);

    if (metaMatch != null && metaMatch.groupCount >= 1) {
      final token = metaMatch.group(1);
      logger.i('Extracted CSRF token from meta tag: $token');
      return token;
    }

    logger.e('Failed to extract CSRF token from HTML');
    return null;
  }

  /// Extracts session cookie from response headers
  ///
  /// Parameters:
  ///
  /// - `response`: The HTTP response object
  /// - `initialCookie`: The initial session cookie
  /// - `logger`: The logger instance
  String extractSessionCookie(http.Response response, String initialCookie) {
    if (response.headers.containsKey('set-cookie')) {
      final setCookieHeader = response.headers['set-cookie']!;
      logger.d('Received Set-Cookie header: $setCookieHeader');

      final sessionMatch = RegExp(
        r'session=([^;]+)',
      ).firstMatch(setCookieHeader);
      if (sessionMatch != null && sessionMatch.groupCount >= 1) {
        final sessionCookie = 'session=${sessionMatch.group(1)}';
        logger.i('Extracted new session cookie: $sessionCookie');
        return sessionCookie;
      }
    }

    // Return original cookie if no new session cookie found
    return initialCookie;
  }

  /// Makes a CSRF-protected POST request
  ///
  /// Parameters:
  ///
  /// - `path`: The path to the API endpoint
  /// - `baseUrl`: The base URL of the server
  /// - `initialCookie`: The initial session cookie
  /// - `additionalFormData`: Additional form data to include in the request
  /// - `customLogger`: Optional custom logger instance
  Future<http.Response?> makeCsrfProtectedRequest({
    required String path,
    required String baseUrl,
    required String initialCookie,
    Map<String, String> additionalFormData = const {},
    Logger? customLogger,
  }) async {
    final logger = customLogger ?? Logger();
    final client = http.Client();

    try {
      // STEP 1: Make GET request to fetch CSRF token
      final getUrl = Uri.parse('$baseUrl$path');
      logger.i('Making initial GET request to: $getUrl');

      final getHeaders = {
        'Cookie': initialCookie,
        'Accept': 'text/html,application/xhtml+xml,application/xml',
      };

      final getResponse = await http.get(getUrl, headers: getHeaders);
      logger.d('GET response status: ${getResponse.statusCode}');

      if (getResponse.statusCode != 200) {
        logger.e('Initial GET request failed: ${getResponse.statusCode}');
        return null;
      }

      // Extract session cookie
      final sessionCookie = extractSessionCookie(getResponse, initialCookie);

      // Extract CSRF token
      final csrfToken = extractCsrfToken(getResponse.body, logger);
      if (csrfToken == null) {
        logger.e('Failed to extract CSRF token');
        return null;
      }

      // STEP 2: Make POST request with the CSRF token
      final postUrl = Uri.parse('$baseUrl$path');
      logger.i('Making POST request to: $postUrl');

      final postHeaders = {
        'Cookie': sessionCookie,
        'X-CSRFToken': csrfToken,
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Referer': '$baseUrl$path',
        'Origin': baseUrl,
      };

      // Create form data with CSRF token and additional fields
      final Map<String, String> formData = {
        'csrf_token': csrfToken,
        ...additionalFormData,
      };

      final encodedBody = formData.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      logger.d('POST headers: $postHeaders');
      logger.d('POST body: $encodedBody');

      final postResponse = await http.post(
        postUrl,
        headers: postHeaders,
        body: encodedBody,
      );

      logger.i('POST response status: ${postResponse.statusCode}');
      logger.d('POST response body: ${postResponse.body}');

      return postResponse;
    } finally {
      client.close();
    }
  }

  /// Parse HTML content from the shelf page
  ShelfDetailModel parseShelfHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Extract shelf name from the h2 tag
    final h2Element = document.querySelector('h2');
    String shelfName = "Unknown Shelf";
    if (h2Element != null) {
      // Clean up the shelf name (remove 'Bücherregal: ' prefix and quotes)
      shelfName = h2Element.text;
      shelfName = shelfName.replaceAll('Bücherregal: ', '').replaceAll("'", "");
    }

    // Extract books
    final List<ShelfBookItem> books = [];
    final bookElements = document.querySelectorAll('.book');

    for (var bookElement in bookElements) {
      // Extract title
      final titleElement = bookElement.querySelector('.title');
      final title = titleElement?.text ?? "Unknown Title";

      // Extract authors
      final authorLinks = bookElement.querySelectorAll('.author a');
      List<BookAuthor> authors = [];
      for (var authorLink in authorLinks) {
        final authorHref = authorLink.attributes['href'] ?? "";
        final authorId = extractIdFromUrl(authorHref);
        authors.add(BookAuthor(name: authorLink.text, id: authorId));
      }

      // Extract series if available
      String? seriesName;
      String? seriesId;
      String? seriesIndex;
      final seriesElement = bookElement.querySelector('.series');
      if (seriesElement != null) {
        final seriesLink = seriesElement.querySelector('a');
        if (seriesLink != null) {
          seriesName = seriesLink.text.trim();
          final seriesHref = seriesLink.attributes['href'] ?? "";
          seriesId = extractIdFromUrl(seriesHref);

          // Get series index from parenthesized text
          final seriesText = seriesElement.text;
          RegExp regExp = RegExp(r'\((\d+(?:\.\d+)?)\)');
          final match = regExp.firstMatch(seriesText);
          if (match != null) {
            seriesIndex = match.group(1);
          }
        }
      }

      // Extract download link and book ID
      String bookId = "";
      String? downloadUrl;

      // Extract book ID from the book link
      final bookLinkElement = bookElement.querySelector(
        'a[data-toggle="modal"]',
      );
      if (bookLinkElement != null) {
        final bookHref = bookLinkElement.attributes['href'];
        if (bookHref != null) {
          RegExp regExp = RegExp(r'/book/(\d+)');
          final match = regExp.firstMatch(bookHref);
          if (match != null) {
            bookId = match.group(1) ?? "";
          }
        }
      }

      final downloadLinkElement = bookElement.querySelector(
        'a[id^="btnGroupDrop"]',
      );
      if (downloadLinkElement != null) {
        downloadUrl = downloadLinkElement.attributes['href'];
      }

      // Create book item
      books.add(
        ShelfBookItem(
          id: bookId,
          title: title,
          authors: authors,
          seriesName: seriesName,
          seriesId: seriesId,
          seriesIndex: seriesIndex,
          downloadUrl: downloadUrl,
        ),
      );
    }

    return ShelfDetailModel(name: shelfName, books: books);
  }

  /// Extract ID from URL like '/author/stored/12345'
  String extractIdFromUrl(String url) {
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : "";
  }
}
