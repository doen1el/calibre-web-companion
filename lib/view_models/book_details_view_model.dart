import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:calibre_web_companion/utils/opds_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class BookDetailsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  JsonService _jsonService = JsonService();

  Logger logger = Logger();
  String? errorMessage;

  Future<BookItem> fetchBook({required String bookUuid}) async {
    return _jsonService.fetchBook(bookUuid: bookUuid);
  }

  Future<bool> downloadBook(
    String bookId,
    String title, {
    String format = 'epub',
  }) async {
    try {
      // Ask user to select download directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        logger.i('Download cancelled: No directory selected');
        return false;
      }

      logger.i('Downloading book - BookId: $bookId, Format: $format');

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url');
      final cookie = prefs.getString('calibre_web_session');
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
      final fileName =
          title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') ?? 'book_$bookId';
      final filePath = path.join(selectedDirectory, '$fileName.$format');

      // Show download in progress
      bool isDownloading = true;
      errorMessage = 'Downloading...';

      // Create HTTP client with proper authentication
      final client = http.Client();
      try {
        // Try cookie authentication first
        final Map<String, String> headers = {};
        if (cookie != null) {
          headers['Cookie'] = cookie;
        } else if (username != null && password != null) {
          // Fall back to basic auth if no cookie
          headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        }

        // Use a stream to handle large files and show progress
        final request = http.Request('GET', Uri.parse(downloadUrl));
        request.headers.addAll(headers);

        final response = await client.send(request);

        logger.i('Download response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Get the total file size for progress calculation
          final contentLength = response.contentLength ?? 0;
          int downloaded = 0;

          // Create file
          final file = File(filePath);
          final sink = file.openWrite();

          // Process the download stream
          await response.stream.forEach((bytes) {
            sink.add(bytes);
            downloaded += bytes.length;

            // Update progress every 500ms to avoid too many UI updates
            final progress =
                contentLength > 0
                    ? (downloaded / contentLength * 100).toInt()
                    : null;

            if (progress != null) {
              errorMessage = 'Downloading... ${progress.toString()}%';
            }
          });

          await sink.close();

          errorMessage = 'Download complete! Saved to:\n$filePath';

          logger.i('Download complete: $filePath');
          return true;
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please log in again.';
          logger.w('Authentication failed');
          return false;
        } else {
          errorMessage =
              'Download failed: Server error (${response.statusCode})';
          logger.e('Failed to download book: ${response.statusCode}');
          return false;
        }
      } finally {
        client.close();
        isDownloading = false;
      }
    } catch (e) {
      errorMessage = 'Download error: $e';
      logger.e('Exception while downloading book: $e');
      return false;
    }
  }

  Future<Uint8List?> downloadBookBytes(
    String bookId, {
    required String format,
  }) async {
    try {
      final apiService = ApiService();
      final baseUrl = apiService.getBaseUrl();
      final username = apiService.getUsername();
      final password = apiService.getPassword();

      // URL für den Download erstellen
      final url = '$baseUrl/opds/download/$bookId/$format';

      // Basic Auth Header erstellen
      final authHeader =
          'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      // Anfrage senden
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': authHeader},
      );

      // Statuscode überprüfen
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        logger.e('Error downloading book: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Exception downloading book: $e');
      return null;
    }
  }

  // Bookmark-Status für das Buch
  bool isBookmarked(String bookId) {
    // Hier die tatsächliche Implementierung basierend auf SharedPreferences oder Datenbank
    return false; // Dummy-Implementierung
  }

  // Lesezeichen umschalten
  void toggleBookmark(String bookId) {
    // Implementiere die Funktion zum Umschalten des Lesezeichen-Status
    // und benachrichtige Listener
    notifyListeners();
  }

  // Prüfen, ob das Buch als gelesen markiert ist
  bool isRead(String bookId) {
    // Hier die tatsächliche Implementierung basierend auf SharedPreferences oder Datenbank
    return false; // Dummy-Implementierung
  }

  /// Toggle the read status of the book
  /// Toggle the read status of the book
  /// Toggle the read status of the book
  Future<bool> toggleReadStatus(String bookId) async {
    try {
      final apiService = ApiService();
      logger.i('Toggling read status for book: $bookId');

      // Create a body with the necessary parameters
      // The server expects a properly formatted body, not null
      final body = {'book_id': bookId};

      final response = await apiService.post(
        '/ajax/toggleread/$bookId',
        null,
        body, // Send the body with book_id instead of null
        AuthMethod.cookie,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully toggled read status');
        // Update local state or cache here if needed
        notifyListeners(); // Update UI
        return true;
      } else {
        logger.e('Failed to toggle read status: ${response.statusCode}');
        errorMessage = 'Failed to update read status (${response.statusCode})';
        return false;
      }
    } catch (e) {
      logger.e('Error toggling read status: $e');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Buch herunterladen
  // Future<bool> downloadBook(
  //   String bookId, {
  //   required String format,
  //   required String title,
  // }) async {
  //   try {
  //     // Ask user to select download directory
  //     String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  //     if (selectedDirectory == null) {
  //       logger.i('Download cancelled: No directory selected');
  //       errorMessage = 'Download cancelled';
  //       // notifyListeners();
  //       return false;
  //     }

  //     logger.i('Downloading book - BookId: $bookId, Format: $format');
  //     errorMessage = 'Starting download...';
  //     // notifyListeners();

  //     // Create sanitized filename from title
  //     final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  //     final fileName = '$sanitizedTitle.$format';
  //     final filePath = path.join(selectedDirectory, fileName);

  //     // Use ApiService for download
  //     final downloadUrl = '/opds/download/$bookId/$format';
  //     final response = await _apiService.download(
  //       downloadUrl,
  //       AuthMethod.basic,
  //     );

  //     logger.i('Download response status: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       // Get total file size for progress calculation
  //       final contentLength = response.contentLength ?? 0;
  //       int downloaded = 0;

  //       // Create file
  //       final file = File(filePath);
  //       final sink = file.openWrite();

  //       // Show initial progress
  //       errorMessage = 'Downloading... 0%';
  //       // notifyListeners();

  //       // Process the download stream
  //       await for (final bytes in response.stream) {
  //         sink.add(bytes);
  //         downloaded += bytes.length;

  //         // Calculate progress percentage
  //         if (contentLength > 0) {
  //           final progress = (downloaded / contentLength * 100).toInt();
  //           errorMessage = 'Downloading... $progress%';
  //           // notifyListeners();
  //         }
  //       }

  //       await sink.close();

  //       errorMessage = 'Download complete! Saved to:\n$filePath';
  //       logger.i('Download complete: $filePath');
  //       notifyListeners();
  //       return true;
  //     } else {
  //       errorMessage = 'Download failed: Server error (${response.statusCode})';
  //       logger.e('Failed to download book: ${response.statusCode}');
  //       // notifyListeners();
  //       return false;
  //     }
  //   } catch (e) {
  //     errorMessage = 'Download error: $e';
  //     logger.e('Exception while downloading book: $e');
  //     // notifyListeners();
  //     return false;
  //   }
  // }

  // Downloads-Ordner öffnen
  void openDownloads() {
    // Implementiere das Öffnen des Downloads-Ordners oder der Downloads-Ansicht in deiner App
  }
}
