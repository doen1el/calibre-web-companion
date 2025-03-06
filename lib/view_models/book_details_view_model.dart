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

  // Future<BookModel> fetchBook({required String bookUuid}) async {
  //   logger.i('Fetching book - UUID: $bookUuid');
  //   errorMessage = null;

  //   try {
  //     final response = await _apiService.get(
  //       '/ajax/book/$bookUuid',
  //       AuthMethod.basic,
  //     );

  //     if (response.statusCode == 200) {
  //       try {
  //         // First, try direct parsing in case it's valid JSON
  //         final bookJson = json.decode(response.body);
  //         final bookModel = BookModel.fromJson(bookJson);
  //         book = bookModel;
  //         return bookModel;
  //       } catch (jsonError) {
  //         // If direct parsing fails, use the manual extraction approach
  //         logger.w('JSON parsing failed: $jsonError. Using manual extraction.');

  //         // Extract data manually using a safer approach
  //         final bookData = _extractBookData(response.body, bookUuid);
  //         final bookModel = BookModel.fromJson(bookData);
  //         book = bookModel;
  //         return bookModel;
  //       }
  //     } else {
  //       errorMessage = 'Server error: ${response.statusCode}';
  //       throw Exception('Server error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     errorMessage = 'Error: $e';
  //     logger.e('Exception while fetching book: $e');
  //     rethrow;
  //   }
  // }

  // // Safer approach to extract book data from malformed JSON
  // Map<String, dynamic> _extractBookData(String responseBody, String bookUuid) {
  //   Map<String, dynamic> result = {
  //     'uuid': bookUuid,
  //     'title': 'Unknown Title',
  //     'authors': ['Unknown Author'],
  //   };

  //   try {
  //     // Extract application_id
  //     final idMatch = RegExp(
  //       r'"application_id":\s*(\d+)',
  //     ).firstMatch(responseBody);
  //     if (idMatch != null) {
  //       result['id'] = int.parse(idMatch.group(1)!);
  //     }

  //     // Extract title (handling problematic quotes)
  //     final titleMatch = RegExp(
  //       r'"title":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
  //       dotAll: true,
  //     ).firstMatch(responseBody);
  //     if (titleMatch != null) {
  //       // Clean up the title by replacing any malformed quotes
  //       String title = titleMatch.group(1)!;
  //       title = title.replaceAll('"', '');
  //       result['title'] = title;
  //     }

  //     // Extract authors array
  //     final authorsSection = _extractSection(responseBody, 'authors');
  //     if (authorsSection != null) {
  //       final authors = _extractStringArray(authorsSection);
  //       if (authors.isNotEmpty) {
  //         result['authors'] = authors;
  //       }
  //     }

  //     // Extract tags array
  //     final tagsSection = _extractSection(responseBody, 'tags');
  //     if (tagsSection != null) {
  //       final tags = _extractStringArray(tagsSection);
  //       if (tags.isNotEmpty) {
  //         result['tags'] = tags;
  //       }
  //     }

  //     // Extract rating
  //     final ratingMatch = RegExp(
  //       r'"rating":\s*"([^"]+)"',
  //     ).firstMatch(responseBody);
  //     if (ratingMatch != null) {
  //       result['ratings'] = ratingMatch.group(1);
  //     }

  //     // Extract has_cover (always true since we have book ID)
  //     result['has_cover'] = true;

  //     // Extract series if available
  //     final seriesMatch = RegExp(
  //       r'"series":\s*"([^"]+)"',
  //     ).firstMatch(responseBody);
  //     if (seriesMatch != null) {
  //       result['series'] = seriesMatch.group(1);
  //     } else {
  //       result['series'] = '';
  //     }

  //     // Extract comments safely (this is particularly problematic)
  //     try {
  //       final commentsMatch = RegExp(
  //         r'"comments":\s*"(.*?)(?<!\\)"(?=,|\s*}|\s*")',
  //         dotAll: true,
  //       ).firstMatch(responseBody);
  //       if (commentsMatch != null) {
  //         String comments = commentsMatch.group(1)!;
  //         // Strip HTML
  //         comments = comments.replaceAll(RegExp(r'<[^>]*>'), '');
  //         result['comments'] = comments;
  //       } else {
  //         result['comments'] = '';
  //       }
  //     } catch (e) {
  //       logger.w('Failed to extract comments: $e');
  //       result['comments'] = '';
  //     }
  //   } catch (e) {
  //     logger.e('Error during manual data extraction: $e');
  //   }

  //   return result;
  // }

  // Helper to extract a section of the JSON between field name and next field
  String? _extractSection(String json, String fieldName) {
    final regex = RegExp('"$fieldName":\\s*(\\[.*?\\])', dotAll: true);
    final match = regex.firstMatch(json);
    return match?.group(1);
  }

  // Helper to extract string array values
  List<String> _extractStringArray(String arrayText) {
    List<String> result = [];
    // Simple but effective approach for well-formed parts
    final matches = RegExp(r'"([^"]+)"').allMatches(arrayText);
    for (var match in matches) {
      if (match.groupCount >= 1) {
        result.add(match.group(1)!);
      }
    }
    return result;
  }

  // Future<bool> downloadBook(int bookId, {String format = 'epub'}) async {
  //   try {
  //     // Ask user to select download directory
  //     String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  //     if (selectedDirectory == null) {
  //       logger.i('Download cancelled: No directory selected');
  //       return false;
  //     }

  //     logger.i('Downloading book - BookId: $bookId, Format: $format');

  //     final prefs = await SharedPreferences.getInstance();
  //     final baseUrl = prefs.getString('base_url');
  //     final cookie = prefs.getString('calibre_web_session');
  //     final username = prefs.getString('username');
  //     final password = prefs.getString('password');

  //     if (baseUrl == null) {
  //       logger.w('No server URL found');
  //       errorMessage = 'Server URL missing';
  //       return false;
  //     }

  //     // Construct download URL
  //     final downloadUrl = '$baseUrl/download/$bookId/$format/$bookId.$format';
  //     logger.d('Download URL: $downloadUrl');

  //     // Create file path
  //     final fileName =
  //         book?.title?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') ??
  //         'book_$bookId';
  //     final filePath = path.join(selectedDirectory, '$fileName.$format');

  //     // Show download in progress
  //     bool isDownloading = true;
  //     errorMessage = 'Downloading...';

  //     // Create HTTP client with proper authentication
  //     final client = http.Client();
  //     try {
  //       // Try cookie authentication first
  //       final Map<String, String> headers = {};
  //       if (cookie != null) {
  //         headers['Cookie'] = cookie;
  //       } else if (username != null && password != null) {
  //         // Fall back to basic auth if no cookie
  //         headers['Authorization'] =
  //             'Basic ${base64.encode(utf8.encode('$username:$password'))}';
  //       }

  //       // Use a stream to handle large files and show progress
  //       final request = http.Request('GET', Uri.parse(downloadUrl));
  //       request.headers.addAll(headers);

  //       final response = await client.send(request);

  //       logger.i('Download response status: ${response.statusCode}');

  //       if (response.statusCode == 200) {
  //         // Get the total file size for progress calculation
  //         final contentLength = response.contentLength ?? 0;
  //         int downloaded = 0;

  //         // Create file
  //         final file = File(filePath);
  //         final sink = file.openWrite();

  //         // Process the download stream
  //         await response.stream.forEach((bytes) {
  //           sink.add(bytes);
  //           downloaded += bytes.length;

  //           // Update progress every 500ms to avoid too many UI updates
  //           final progress =
  //               contentLength > 0
  //                   ? (downloaded / contentLength * 100).toInt()
  //                   : null;

  //           if (progress != null) {
  //             errorMessage = 'Downloading... ${progress.toString()}%';
  //           }
  //         });

  //         await sink.close();

  //         errorMessage = 'Download complete! Saved to:\n$filePath';

  //         logger.i('Download complete: $filePath');
  //         return true;
  //       } else if (response.statusCode == 401) {
  //         errorMessage = 'Authentication failed. Please log in again.';
  //         logger.w('Authentication failed');
  //         return false;
  //       } else {
  //         errorMessage =
  //             'Download failed: Server error (${response.statusCode})';
  //         logger.e('Failed to download book: ${response.statusCode}');
  //         return false;
  //       }
  //     } finally {
  //       client.close();
  //       isDownloading = false;
  //     }
  //   } catch (e) {
  //     errorMessage = 'Download error: $e';
  //     logger.e('Exception while downloading book: $e');
  //     return false;
  //   }
  // }
}
