import 'dart:convert';
import 'package:calibre_web_companion/models/download_service_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadServiceViewModel extends ChangeNotifier {
  Logger logger = Logger();

  // Bool values
  bool isSearching = false;
  bool isLoading = false;

  // Lists
  List<Book> _searchResults = [];
  List<Book> _books = [];

  // Getters
  List<Book> get searchResults => _searchResults;
  List<Book> get books => _books;

  // Error handling
  String? error;

  /// Get the base URL for the downloader
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString('downloader_url') ?? '';
  }

  /// Search for books by query
  ///
  /// Parameters:
  ///
  /// - `query`: String
  Future<void> searchBooks(String query) async {
    isSearching = true;
    error = null;
    _searchResults = [];
    notifyListeners();

    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/search?query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        _searchResults =
            results.map((json) => Book.fromSearchResponse(json)).toList();

        logger.i('Found ${_searchResults.length} books matching "$query"');
      } else {
        error = 'Failed to search books: ${response.statusCode}';
        logger.e(error!);
      }
    } catch (e) {
      error = 'Error searching books: $e';
      logger.e(error!);
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  /// Download a book by ID
  ///
  /// Parameters:
  ///
  /// - `bookId`: String
  Future<void> downloadBook(String bookId) async {
    final baseUrl = await getBaseUrl();

    final response = await http.get(
      Uri.parse('$baseUrl/api/download?id=$bookId'),
    );

    logger.i(
      'Making download request for $bookId on ${'$baseUrl/api/download/$bookId'}',
    );

    if (response.statusCode == 200) {
      final status = json.decode(response.body);
      logger.i('Download status: $status');
      // Handle successful response
      logger.i('Download request successful');
    } else {
      // Handle error response
      logger.e('Failed to download book: ${response.body}');
      throw Exception('Failed to download book');
    }
  }

  /// Get the download status of all books
  Future<void> getDownloadStatus() async {
    final baseUrl = await getBaseUrl();

    final response = await http.get(Uri.parse('$baseUrl/api/status'));

    isLoading = true;
    notifyListeners();

    try {
      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        final downloadStatus = DownloadStatusResponse.fromJson(status);

        // Get all books with their status
        _books = downloadStatus.getAllBooks();

        logger.i('Found ${_books.length} books with download status');

        // Log book counts by status for debugging
        final availableCount =
            _books
                .where((b) => b.status == DownloadServiceStatus.available)
                .length;
        final downloadingCount =
            _books
                .where((b) => b.status == DownloadServiceStatus.downloading)
                .length;
        final doneCount =
            _books.where((b) => b.status == DownloadServiceStatus.done).length;
        final errorCount =
            _books.where((b) => b.status == DownloadServiceStatus.error).length;
        final queuedCount =
            _books
                .where((b) => b.status == DownloadServiceStatus.queued)
                .length;

        logger.d(
          'Books by status: Available: $availableCount, Downloading: $downloadingCount, '
          'Done: $doneCount, Error: $errorCount, Queued: $queuedCount',
        );
      } else {
        error = 'Failed to get status: ${response.statusCode}';
        logger.e(error!);
      }
    } catch (e) {
      error = 'Error fetching download status: $e';
      logger.e(error!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get books by status
  ///
  /// Parameters:
  ///
  /// - `status`: BookDownloadStatus
  List<Book> getBooksByStatus(DownloadServiceStatus status) {
    return _books.where((book) => book.status == status).toList();
  }
}
