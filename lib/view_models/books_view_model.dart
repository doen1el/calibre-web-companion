import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

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
  String _sortBy = 'added';
  String _sortOrder = 'asc';
  String? _searchQuery;

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
        sortBy: _sortBy == "added" ? "" : _sortBy,
        sortOrder: _sortOrder,
      );
      if (_offset == 0) {
        books = result;
      } else {
        books.addAll(result);

        if (_sortBy == 'added') {
          if (_sortOrder == 'asc') {
            books = books.reversed.toList();
          }
        }
      }
      _offset += result.length;
      hasMoreBooks = result.length == _limit;
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
}
