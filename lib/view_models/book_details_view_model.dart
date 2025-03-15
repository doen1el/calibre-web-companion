import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class BookDetailsViewModel extends ChangeNotifier {
  final JsonService _jsonService = JsonService();

  Logger logger = Logger();
  String? errorMessage;

  bool isDownloading = false;
  int downloaded = 0;

  bool _isBookRead = false;
  bool get isBookRead => _isBookRead;

  bool _isReadToggleLoading = false;
  bool get isReadToggleLoading => _isReadToggleLoading;

  bool _isArchived = false;
  bool get isArchived => _isArchived;

  bool _isArchivedLoading = false;
  bool get isArchivedLoading => _isArchivedLoading;

  /// Fetch the book details from the server
  ///
  /// Parameters:
  ///
  /// - `bookUuid`: The unique identifier of the book
  Future<BookItem> fetchBook({required String bookUuid}) async {
    BookItem book = await _jsonService.fetchBook(bookUuid: bookUuid);

    await checkIfBookIsRead(book.id);
    return book;
  }

  /// Fetch the book details from the server
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `title`: The title of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  Future<bool> downloadBook(
    String bookId,
    String title,
    String selectedDirectory, {
    String format = 'epub',
  }) async {
    try {
      format = format.toLowerCase();

      logger.i('Downloading book - BookId: $bookId, Format: .epub');
      isDownloading = true;
      downloaded = 0;
      notifyListeners();

      final apiService = ApiService();
      final baseUrl = apiService.getBaseUrl();
      final username = apiService.getUsername();
      final password = apiService.getPassword();

      if (baseUrl.isEmpty) {
        logger.w('No server URL found');
        errorMessage = 'Server URL missing';
        return false;
      }

      final downloadUrl = '$baseUrl/download/$bookId/epub/$bookId.epub';
      logger.d('Download URL: $downloadUrl');

      final fileName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = path.join(selectedDirectory, '$fileName.$format');

      final client = http.Client();
      try {
        final Map<String, String> headers = {};

        final prefs = await SharedPreferences.getInstance();
        final cookie = prefs.getString('calibre_web_session');
        if (cookie != null && cookie.isNotEmpty) {
          headers['Cookie'] = cookie;
        }

        final request = http.Request('GET', Uri.parse(downloadUrl));
        request.headers.addAll(headers);

        final response = await client.send(request);
        final contentLength = response.contentLength ?? -1;

        logger.i(
          'Download response status: ${response.statusCode}, Content length: $contentLength',
        );

        if (response.statusCode == 200) {
          final file = File(filePath);
          final sink = file.openWrite();
          int receivedBytes = 0;

          try {
            await for (final chunk in response.stream) {
              receivedBytes += chunk.length;
              sink.add(chunk);

              downloaded = receivedBytes;
              if (contentLength > 0) {
                final progress = (receivedBytes / contentLength * 100).round();
                logger.d(
                  'Download progress: $progress%, $receivedBytes/$contentLength bytes',
                );
              }
              notifyListeners();
            }
          } finally {
            await sink.flush();
            await sink.close();
          }

          logger.i('Download complete: $filePath with $receivedBytes bytes');
          return true;
        } else if (response.statusCode == 401) {
          logger.w('Authentication failed');
          errorMessage = 'Authentication failed';
          return false;
        } else {
          logger.e('Failed to download book: ${response.statusCode}');
          errorMessage = 'HTTP error ${response.statusCode}';
          return false;
        }
      } catch (e) {
        logger.e('Exception in download stream: $e');
        errorMessage = 'Download error: $e';
        return false;
      } finally {
        client.close();
        isDownloading = false;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Exception while downloading book: $e');
      errorMessage = 'Error: $e';
      isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Download book bytes from the server
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  Future<Uint8List?> downloadBookBytes(
    String bookId, {
    required String format,
  }) async {
    try {
      // Get authentication details as in downloadBook
      final apiService = ApiService();
      final baseUrl = apiService.getBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('calibre_web_session');
      final username = apiService.getUsername();
      final password = apiService.getPassword();

      if (baseUrl.isEmpty) {
        logger.w('No server URL found');
        return null;
      }

      final url = '$baseUrl/download/$bookId/$format/$bookId.$format';
      logger.d('Download URL: $url');

      // Create HTTP client with proper authentication
      final client = http.Client();
      try {
        // Setup headers with cookie-first authentication strategy
        final Map<String, String> headers = {};
        if (cookie != null && cookie.isNotEmpty) {
          // Try cookie authentication first
          headers['Cookie'] = cookie;
        } else if (username.isNotEmpty && password.isNotEmpty) {
          // Fall back to basic auth if no cookie
          headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        } else {
          logger.e('No authentication credentials available');
          return null;
        }

        // Use the same request method as downloadBook for consistency
        final request = http.Request('GET', Uri.parse(url));
        request.headers.addAll(headers);

        final response = await client.send(request);

        // Check status code
        if (response.statusCode == 200) {
          logger.i('Successfully downloaded book bytes');
          // Convert the streamed response to bytes
          final bytes = await response.stream.toBytes();
          return bytes;
        } else if (response.statusCode == 401) {
          logger.e('Authentication failed: 401 Unauthorized');
          return null;
        } else {
          logger.e('Error downloading book: HTTP ${response.statusCode}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      logger.e('Exception downloading book: $e');
      return null;
    }
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
  String extractSessionCookie(
    http.Response response,
    String initialCookie,
    Logger logger,
  ) {
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
      final sessionCookie = extractSessionCookie(
        getResponse,
        initialCookie,
        logger,
      );

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

  /// Send book via email
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  /// - `conversion`: The conversion type (0 = original, 1 = MOBI, 2 = AZW3)
  Future<bool> sendViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      logger.i(
        'Starting email send process for bookId: $bookId, format: $format, conversion: $conversion',
      );

      // Get stored authentication details
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? '';
      final storedCookie = prefs.getString('calibre_web_session') ?? '';

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        errorMessage = 'Server URL missing';
        return false;
      }

      final path = '/send/$bookId/$format/$conversion';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 200) {
        logger.i('Successfully sent book via email');
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to send book via email: $statusCode');
        errorMessage = 'Failed to send email ($statusCode)';
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error sending book via email: $e');
      logger.d('Stack trace: $stackTrace');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Toggle the read status of a book
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<bool> toggleReadStatus(String bookId) async {
    try {
      _isReadToggleLoading = true;
      notifyListeners();
      logger.i('Starting toggling read status for bookId: $bookId');

      // Get stored authentication details
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? '';
      final storedCookie = prefs.getString('calibre_web_session') ?? '';

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        errorMessage = 'Server URL missing';
        return false;
      }

      final path = '/ajax/toggleread/$bookId';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 200) {
        logger.i('Successfully toggled read status');
        await checkIfBookIsRead(bookId);
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to toggle read status: $statusCode');
        errorMessage = 'Failed to toggle read status ($statusCode)';
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error sending toggling read statu: $e');
      logger.d('Stack trace: $stackTrace');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      _isReadToggleLoading = false;
      notifyListeners();
    }
  }

  /// Check if the book is read
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<void> checkIfBookIsRead(String bookId) async {
    BookListViewModel bookListViewModel = BookListViewModel();

    await bookListViewModel.loadBooks(BookListType.readbooks);

    bookListViewModel.bookFeed?.items.forEach((element) async {
      if (element.id == bookId) {
        _isBookRead = true;
        notifyListeners();
      } else {
        _isBookRead = false;
        notifyListeners();
      }
    });
  }

  /// Toggle the archived status of a book
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<bool> toggleArchivedStatus(String bookId) async {
    try {
      _isArchivedLoading = true;
      notifyListeners();
      logger.i('Starting toggling archived status for bookId: $bookId');

      // Get stored authentication details
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? '';
      final storedCookie = prefs.getString('calibre_web_session') ?? '';

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        errorMessage = 'Server URL missing';
        return false;
      }

      final path = '/ajax/togglearchived/$bookId';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 200) {
        logger.i('Successfully toggled archived status');
        _isArchived = !_isArchived;
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to toggle archived status: $statusCode');
        errorMessage = 'Failed to toggle archived status ($statusCode)';
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error sending toggling archived statu: $e');
      logger.d('Stack trace: $stackTrace');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      _isArchivedLoading = false;

      notifyListeners();
    }
  }
}
