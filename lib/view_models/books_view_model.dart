import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:calibre_web_companion/models/book_model.dart';

class BooksViewModel extends ChangeNotifier {
  Logger logger = Logger();
  List<BookModel> books = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  bool hasMoreBooks = true;

  // Pagination parameters
  int _offset = 0;
  final int _limit = 20;

  // Sorting parameters
  String _sortBy = 'title';
  String _sortOrder = 'asc';
  String? _searchQuery;

  // Get server URL
  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url');
  }

  // Reset and fetch books from beginning
  Future<void> refreshBooks() async {
    // Reset pagination
    _offset = 0;
    books.clear();
    hasMoreBooks = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    // Fetch first page
    await fetchMoreBooks();
  }

  // Set sorting and refresh
  void setSorting(String sortBy, String order) {
    _sortBy = sortBy;
    _sortOrder = order;
    refreshBooks();
  }

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    refreshBooks();
  }

  // Fetch more books (called when scrolling or initially)
  Future<void> fetchMoreBooks() async {
    if (isLoading || !hasMoreBooks) return;

    isLoading = true;
    notifyListeners();

    try {
      final result = await fetchBooks(
        offset: _offset,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        searchQuery: _searchQuery,
      );

      final newBooks = parseBooks(result);

      // If we got fewer books than requested, we've reached the end
      if (newBooks.length < _limit) {
        hasMoreBooks = false;
      }

      // Add new books to our list
      books.addAll(newBooks);

      // Update offset for next fetch
      _offset += newBooks.length;
    } catch (e) {
      logger.e('Error fetching more books: $e');
      hasError = true;
      errorMessage = 'Failed to load books: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Core method to fetch books with parameters
  Future<Map<String, dynamic>> fetchBooks({
    required int offset,
    required int limit,
    String sortBy = 'title',
    String sortOrder = 'asc',
    String? searchQuery,
  }) async {
    logger.i(
      'Fetching books - offset: $offset, limit: $limit, sort: $sortBy, order: $sortOrder',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('calibre_web_session');
      final baseUrl = prefs.getString('base_url');

      if (cookie == null || baseUrl == null) {
        logger.w('No session cookie or server URL found');
        throw Exception('Not logged in or server URL missing');
      }

      // Build query parameters
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sortBy,
        'order': sortOrder,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
      };

      final uri = Uri.parse(
        '$baseUrl/ajax/listbooks',
      ).replace(queryParameters: queryParams);

      logger.d('Request URL: ${uri.toString()}');

      final client = http.Client();
      try {
        final response = await client.get(uri, headers: {'Cookie': cookie});

        logger.i('Book list response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> booksJson = json.decode(response.body);
          return booksJson;
        } else if (response.statusCode == 401) {
          logger.w('Session expired or invalid');
          throw Exception('Session expired. Please log in again.');
        } else {
          logger.e('Failed to fetch books: ${response.statusCode}');
          throw Exception('Server error: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      logger.e('Exception while fetching books: $e');
      rethrow;
    }
  }

  // Parse the response into a list of BookModel objects
  List<BookModel> parseBooks(Map<String, dynamic> response) {
    List<BookModel> result = [];

    if (response.containsKey('rows') && response['rows'] is List) {
      final List<dynamic> rows = response['rows'];
      for (var bookData in rows) {
        try {
          result.add(BookModel.fromJson(bookData));
        } catch (e) {
          logger.w('Error parsing book: $e');
          // Continue with next book
        }
      }
    }

    logger.i('Parsed ${result.length} books');
    return result;
  }

  Future<Uint8List?> fetchImageWithAuth(
    bookId,
    CoverResolution resolution,
  ) async {
    try {
      // Get session cookie
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('calibre_web_session');

      final serverUrl = await getServerUrl();

      if (cookie == null || serverUrl == null) {
        logger.w('No session cookie or server URL found');
        return null;
      }

      // Construct the cover URL
      final url = '$serverUrl/cover/$bookId/$resolution';

      // Make authenticated request
      final response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': cookie},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      debugPrint('Error loading cover image: $e');
      return null;
    }
  }
}
