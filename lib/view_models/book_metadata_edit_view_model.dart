import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookMetadataEditViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorsController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController seriesController = TextEditingController();
  final TextEditingController seriesIndexController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController publisherController = TextEditingController();
  final TextEditingController languageController = TextEditingController();
  final TextEditingController pubdateController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final Logger logger = Logger();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    titleController.dispose();
    authorsController.dispose();
    commentsController.dispose();
    tagsController.dispose();
    seriesController.dispose();
    seriesIndexController.dispose();
    ratingController.dispose();
    publisherController.dispose();
    languageController.dispose();
    pubdateController.dispose();
    super.dispose();
  }

  Future<void> initializeWithBook(BookItem book) async {
    titleController.text = book.title;
    authorsController.text = book.author;
    commentsController.text = book.summary ?? '';
    tagsController.text = book.categories.join(', ');
    seriesController.text = book.series ?? '';
    seriesIndexController.text = book.seriesIndex?.toString() ?? '';
    ratingController.text = book.rating?.toString() ?? '';
    publisherController.text = book.publisher ?? '';
    languageController.text = book.language ?? '';

    if (book.published != null) {
      pubdateController.text = book.published!.toIso8601String().split('T')[0];
    }

    notifyListeners();
  }

  Future<bool> saveMetadata(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logger.i('Starting saving metadata for book $bookId');

      // Get stored authentication details
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? '';
      final storedCookie = prefs.getString('calibre_web_session') ?? '';

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        _errorMessage = 'Server URL missing';
        return false;
      }

      final path = '/admin/book/$bookId';

      // Create form data
      Map<String, String> additionalFormData = {};

      additionalFormData['title'] = titleController.text;
      additionalFormData['authors'] = authorsController.text;
      additionalFormData['comments'] = commentsController.text;
      additionalFormData['tags'] = tagsController.text;
      additionalFormData['series'] = seriesController.text;
      additionalFormData['series_index'] = seriesIndexController.text;
      additionalFormData['rating'] = ratingController.text;
      additionalFormData['publisher'] = publisherController.text;
      additionalFormData['languages'] = languageController.text;
      additionalFormData['pubdate'] = pubdateController.text;
      additionalFormData['detail_view'] = 'on';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
        additionalFormData: additionalFormData,
      );

      if (response != null && response.statusCode == 302) {
        logger.i('Successfully edited book metadata');
        return true;
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to edit book metadata: $statusCode');
        _errorMessage = 'Failed to edit book metadata ($statusCode)';
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error editing book metadata: $e');
      logger.d('Stack trace: $stackTrace');
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
