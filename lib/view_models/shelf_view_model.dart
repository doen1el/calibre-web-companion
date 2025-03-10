import 'dart:convert';

import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShelfViewModel extends ChangeNotifier {
  ApiService apiService = ApiService();
  Logger logger = Logger();

  List<ShelfModel> _shelves = [];
  bool _isLoading = false;

  List<ShelfModel> get shelves => _shelves;
  bool get isLoading => _isLoading;

  Future<void> loadShelfs() async {
    try {
      _isLoading = true;
      notifyListeners(); // Notify loading state changed

      final res = await apiService.getXmlAsJson(
        '/opds/shelfindex',
        AuthMethod.basic,
      );

      // Use fromFeedJson instead of trying to cast res as List
      _shelves = ShelfModel.fromFeedJson(res);

      logger.i("Successfully loaded ${_shelves.length} shelves");
    } catch (e) {
      logger.e("Error loading shelves: $e");
      // Clear shelves on error to ensure we don't have stale data
      _shelves = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

      final path = '/shelf/add/$bookId/$shelfId';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 204) {
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

      final path = '/shelf/remove/$bookId/$shelfId';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 204) {
        logger.i('Successfully removing from shelf');
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

  Future<void> createShelf() async {
    try {
      logger.i('Starting creating shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return;
      }

      final path = '/shelf/create';

      // Make the CSRF-protected request
      final response = await makeCsrfProtectedRequest(
        path: path,
        baseUrl: baseUrl,
        initialCookie: storedCookie,
        customLogger: logger,
      );

      if (response != null && response.statusCode == 302) {
        logger.i('Successfully created shelf');
      } else {
        final statusCode = response?.statusCode ?? 0;
        logger.e('Failed to create shelf: $statusCode');
      }
    } catch (e, stackTrace) {
      logger.e('Error creatig shelf: $e');
      logger.d('Stack trace: $stackTrace');
    } finally {
      notifyListeners();
    }
  }

  Future<void> editShelf(String shelfId) async {
    notifyListeners();
  }

  Future<void> deleteShelf(String shelfId, String bookId) async {
    notifyListeners();
  }

  Future<void> getShelf(String shelfId) async {
    try {
      logger.i('Starting getting shelf');

      final baseUrl = await getBaseUrl();
      final storedCookie = await getStoredCookie();

      if (baseUrl.isEmpty) {
        logger.e('No base URL configured');
        return;
      }

      final path = '/simpleshelf/$shelfId';

      // Make the CSRF-protected request
      final response = await apiService.get(path, AuthMethod.cookie);

      if (response.statusCode == 200) {
        logger.i('Successfully got shelf');
        logger.d("Response body: ${response.body}");
      } else {
        logger.e('Failed to get shelf: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e('Error getting shelf: $e');
      logger.d('Stack trace: $stackTrace');
    } finally {
      notifyListeners();
    }
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? '';
  }

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
}
