import 'dart:io';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:calibre_web_companion/views/books_view.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class BooksViewModel extends ChangeNotifier {
  final JsonService _jsonService = JsonService();

  Logger logger = Logger();
  List<BookItem> books = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasMoreBooks = true;

  // Pagination parameters
  int _offset = 0;
  final int _limit = 20;

  // Sorting parameters
  String _sortBy = '';
  String _sortOrder = '';
  String? _searchQuery;

  // Column count for grid view
  int _columnCount = 2; // Default-Wert
  double get columnCount => _columnCount.toDouble();

  /// Reset and fetch books from beginning and fetches books
  Future<void> refreshBooks() async {
    // Reset pagination
    _offset = 0;
    books.clear();
    hasMoreBooks = true;
    await _fetchBooks();
  }

  /// Fetch more books
  Future<void> fetchMoreBooks() async {
    await _fetchBooks();
  }

  /// Fetch books from the API
  Future<void> _fetchBooks() async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      final result = await _jsonService.fetchBooks(
        offset: _offset,
        limit: _limit,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (_offset == 0) {
        books = result;
      } else {
        books.addAll(result);
      }
      _offset += result.length;
      // Hotfix for weird authors pagination issue
      if (_sortBy == 'authors') {
        hasMoreBooks = true;
      } else {
        hasMoreBooks = result.length == _limit;
      }
      logger.i('Has more books: $hasMoreBooks');
    } catch (e) {
      logger.e('Error fetching books: $e');
      hasError = true;
      errorMessage = 'Failed to load books: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Set sorting and refresh
  ///
  /// Parameters:
  ///
  /// - `sortBy`: The field to sort by
  /// - `order`: The order to sort by
  void setSorting(String sortBy, String order) {
    logger.i('Sorting by $sortBy $order');
    _sortBy = sortBy;
    _sortOrder = order;
    refreshBooks();
  }

  /// Set search query
  ///
  /// Parameters:
  ///
  /// - `query`: The search query to set
  void setSearchQuery(String? query) {
    _searchQuery = query;
    refreshBooks();
  }

  Future<bool> uploadEbookToCalibre(
    File book,
    CancellationToken cancelToken,
  ) async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      logger.i('Starting upload of book: ${book.path.split('/').last}');

      // Hole das CSRF-Token von der Hauptseite statt von /upload
      final csrfResult = await _jsonService.getApiService().fetchCsrfToken(
        '/', // Verwende die Hauptseite statt /upload
        AuthMethod.cookie,
        'input[name="csrf_token"]',
      );

      final csrfToken = csrfResult['token'];
      if (csrfToken == null) {
        throw Exception('Failed to get CSRF token for upload');
      }

      logger.d('Got CSRF token: $csrfToken');

      // Rest des Codes bleibt gleich
      final uri = Uri.parse(
        '${_jsonService.getApiService().getBaseUrl()}/upload',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add authentication cookies
      request.headers['Cookie'] = csrfResult['cookies'] ?? '';

      // Add CSRF token as form field
      request.fields['csrf_token'] = csrfToken;

      // Add the file
      final fileName = book.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      if (fileExtension == 'epub') {
        contentType = 'application/epub+zip';
      } else if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      } else if (fileExtension == 'mobi') {
        contentType = 'application/x-mobipocket-ebook';
      }

      // Add file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'btn-upload',
          book.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Add empty btn-upload2 field required by Calibre-Web
      request.fields['btn-upload2'] = '';

      // Set a timeout to handle potential long uploads
      final client = http.Client();
      try {
        // Send the request with timeout
        final streamedResponse = await client
            .send(request)
            .timeout(
              Duration(seconds: 60),
              onTimeout: () {
                cancelToken.cancel();
                throw TimeoutException('Upload request timed out');
              },
            );

        // Convert the streamed response to a regular response to check status
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 302) {
          logger.i('Book uploaded successfully: ${fileName}');
          return true;
        } else {
          logger.e('Failed to upload book: Status ${response.statusCode}');
          errorMessage = 'Upload failed with status ${response.statusCode}';
          hasError = true;
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      logger.e('Error uploading book: $e');
      errorMessage = 'Upload error: $e';
      hasError = true;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Set the column count for the grid view
  ///
  /// Parameters:
  ///
  /// - `count`: The number of columns to set (1-5)
  Future<void> setColumnCount(int count) async {
    if (count < 1) count = 1;
    if (count > 5) count = 5;

    _columnCount = count;

    // Save the column count to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_column_count', count);

    notifyListeners();
  }

  /// Load the column count from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _columnCount = prefs.getInt('grid_column_count') ?? 2;
    notifyListeners();
  }
}
