import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_status_response.dart';

class DownloadServiceRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;
  final Logger logger;

  DownloadServiceRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
    required this.logger,
  });

  /// Get the base URL for the downloader
  Future<String> _getBaseUrl() async {
    return sharedPreferences.getString('downloader_url') ?? '';
  }

  Future<List<DownloadServiceBookModel>> searchBooks(String query) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await client.get(
        Uri.parse('$baseUrl/api/search?query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        final books =
            results
                .map(
                  (json) => DownloadServiceBookModel.fromSearchResponse(json),
                )
                .toList();
        logger.i('Found ${books.length} books matching "$query"');
        return books;
      } else {
        final errorMessage =
            'Failed to search books: ${response.statusCode} ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error searching books: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<bool> downloadBook(String bookId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await client.get(
        Uri.parse('$baseUrl/api/download?id=$bookId'),
      );

      logger.i('Making download request for $bookId');

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        logger.i('Download status: $status');
        return true;
      } else {
        final errorMessage = 'Failed to download book: ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error downloading book: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<List<DownloadServiceBookModel>> getDownloadStatus() async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await client.get(Uri.parse('$baseUrl/api/status'));

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        final downloadStatus = DownloadStatusResponse.fromJson(status);
        final books = downloadStatus.getAllBooks();

        logger.i('Found ${books.length} books with download status');

        // Log book counts by status for debugging
        final availableCount =
            books.where((b) => b.status == DownloaderStatus.available).length;
        final downloadingCount =
            books.where((b) => b.status == DownloaderStatus.downloading).length;
        final doneCount =
            books.where((b) => b.status == DownloaderStatus.done).length;
        final errorCount =
            books.where((b) => b.status == DownloaderStatus.error).length;
        final queuedCount =
            books.where((b) => b.status == DownloaderStatus.queued).length;

        logger.d(
          'Books by status: Available: $availableCount, Downloading: $downloadingCount, '
          'Done: $doneCount, Error: $errorCount, Queued: $queuedCount',
        );

        return books;
      } else {
        final errorMessage = 'Failed to get status: ${response.statusCode}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error fetching download status: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }
}
