import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
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

  /// Fetch the book details from the server
  ///
  /// Parameters:
  ///
  /// - `bookUuid`: The unique identifier of the book
  Future<BookItem> fetchBook({required String bookUuid}) async {
    return _jsonService.fetchBook(bookUuid: bookUuid);
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
      logger.i('Downloading book - BookId: $bookId, Format: $format');

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url');
      final username = prefs.getString('username');
      final password = prefs.getString('password');

      if (baseUrl == null) {
        logger.w('No server URL found');
        errorMessage = 'Server URL missing';
        return false;
      }

      // Construct download URL
      final downloadUrl = '$baseUrl/download/$bookId/$format/$bookId.$format';
      logger.d('Download URL: $downloadUrl');

      // Create file path
      final fileName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = path.join(selectedDirectory, '$fileName.$format');

      // Create HTTP client with proper authentication
      final client = http.Client();
      try {
        // Try cookie authentication first
        final Map<String, String> headers = {};

        // Fall back to basic auth if no cookie
        headers['Authorization'] =
            'Basic ${base64.encode(utf8.encode('$username:$password'))}';

        // Use a stream to handle large files and show progress
        final request = http.Request('GET', Uri.parse(downloadUrl));
        request.headers.addAll(headers);

        final response = await client.send(request);

        logger.i('Download response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Create file
          final file = File(filePath);
          final sink = file.openWrite();

          // Process the download stream
          await response.stream.forEach((bytes) {
            sink.add(bytes);
          });

          await sink.close();

          logger.i('Download complete: $filePath');

          return true;
        } else if (response.statusCode == 401) {
          logger.w('Authentication failed');
          return false;
        } else {
          logger.e('Failed to download book: ${response.statusCode}');
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      logger.e('Exception while downloading book: $e');
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

      final url = '$baseUrl/download/$bookId/$format/$bookId.epub';
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

  // // Bookmark-Status für das Buch
  // bool isBookmarked(String bookId) {
  //   // Hier die tatsächliche Implementierung basierend auf SharedPreferences oder Datenbank
  //   return false; // Dummy-Implementierung
  // }

  // // Lesezeichen umschalten
  // void toggleBookmark(String bookId) {
  //   // Implementiere die Funktion zum Umschalten des Lesezeichen-Status
  //   // und benachrichtige Listener
  //   notifyListeners();
  // }

  // // Prüfen, ob das Buch als gelesen markiert ist
  // bool isRead(String bookId) {
  //   // Hier die tatsächliche Implementierung basierend auf SharedPreferences oder Datenbank
  //   return false; // Dummy-Implementierung
  // }

  // Future<bool> toggleReadStatus(String bookId) async {
  //   try {
  //     final apiService = ApiService();
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     logger.i('Toggling read status for book: $bookId');

  //     // Get CSRF token first using existing method
  //     final csrfData = await apiService.fetchCsrfToken(
  //       '/book/$bookId',
  //       AuthMethod.cookie,
  //       'input[name="csrf_token"]',
  //     );

  //     if (csrfData['token'] == null) {
  //       logger.e('Failed to get CSRF token');
  //       errorMessage = 'Could not get security token';
  //       return false;
  //     }

  //     final csrfToken = csrfData['token']!;
  //     final baseUrl = apiService.getBaseUrl();
  //     final cookie = prefs.getString('calibre_web_session');

  //     // Use http package directly
  //     final url = Uri.parse('$baseUrl/ajax/toggleread/$bookId');

  //     // Set headers exactly like jQuery would
  //     final headers = {
  //       'Cookie': cookie!,
  //       'X-CSRFToken': csrfToken,
  //       'X-Requested-With': 'XMLHttpRequest',
  //       'Content-Type':
  //           'application/x-www-form-urlencoded', // Simplified Content-Type
  //       'Referer': '$baseUrl/book/$bookId',
  //       'Accept': '*/*', // jQuery default
  //     };

  //     // KEY CHANGE: Try with book_id parameter instead of csrf_token
  //     final body = 'book_id=$bookId';

  //     logger.i('Sending POST request to: $url with body: $body');
  //     final response = await http.post(url, headers: headers, body: body);

  //     logger.i(
  //       'Response status: ${response.statusCode}, body: ${response.body}',
  //     );

  //     if (response.statusCode == 200) {
  //       logger.i('Successfully toggled read status');
  //       notifyListeners();
  //       return true;
  //     } else {
  //       logger.e('Failed to toggle read status: ${response.statusCode}');
  //       errorMessage = 'Failed to update read status (${response.statusCode})';
  //       return false;
  //     }
  //   } catch (e) {
  //     logger.e('Error toggling read status: $e');
  //     errorMessage = 'Error: $e';
  //     return false;
  //   } finally {
  //     notifyListeners();
  //   }
  // }
}
