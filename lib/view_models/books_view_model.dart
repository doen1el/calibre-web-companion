import 'dart:convert';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/opds_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BooksViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final OpdsService _opdsService = OpdsService();

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
  String _sortBy = 'title';
  String _sortOrder = 'asc';
  String? _searchQuery;

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
    await _opdsService
        .fetchBooks(
          offset: _offset,
          limit: _limit,
          searchQuery: _searchQuery,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        )
        .then((result) {
          books = result;
          _offset += result.length;
        })
        .catchError((e) {
          logger.e('Error fetching books: $e');
          hasError = true;
          errorMessage = 'Failed to load books: $e';
        })
        .whenComplete(() {
          isLoading = false;
          notifyListeners();
        });
  }

  Future<void> fetchMoreBooks() async {
    await _opdsService
        .fetchBooks(
          offset: _offset,
          limit: _limit,
          searchQuery: _searchQuery,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        )
        .then((result) {
          books = result;
          _offset += result.length;
        })
        .catchError((e) {
          logger.e('Error fetching books: $e');
          hasError = true;
          errorMessage = 'Failed to load books: $e';
        })
        .whenComplete(() {
          isLoading = false;
          notifyListeners();
        });
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

  // // Fetch more books (called when scrolling or initially)
  // Future<void> fetchMoreBooks() async {
  //   if (isLoading || !hasMoreBooks) return;

  //   isLoading = true;
  //   notifyListeners();

  //   try {
  //     final queryParams = {
  //       'offset': _offset.toString(),
  //       'limit': _limit.toString(),
  //       'sort': _sortBy,
  //       'order': _sortOrder,
  //     };

  //     if (_searchQuery != null && _searchQuery!.isNotEmpty) {
  //       queryParams['search'] = _searchQuery!;
  //     }

  //     final result = await _apiService.getJson(
  //       '/ajax/listbooks',
  //       AuthMethod.cookie,
  //       queryParams: queryParams,
  //     );
  //     final newBooks = parseBooks(result);

  //     // If we got fewer books than requested, we've reached the end
  //     if (newBooks.length < _limit) {
  //       hasMoreBooks = false;
  //     }

  //     // Add new books to our list
  //     books.addAll(newBooks);

  //     // Update offset for next fetch
  //     _offset += newBooks.length;
  //   } catch (e) {
  //     logger.e('Error fetching more books: $e');
  //     hasError = true;
  //     errorMessage = 'Failed to load books: $e';
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Parse the response into a list of BookModel objects
  // List<BookModel> parseBooks(Map<String, dynamic> response) {
  //   List<BookModel> result = [];

  //   if (response.containsKey('rows') && response['rows'] is List) {
  //     final List<dynamic> rows = response['rows'];
  //     for (var bookData in rows) {
  //       try {
  //         result.add(BookModel.fromJson(bookData));
  //       } catch (e) {
  //         logger.w('Error parsing book: $e');
  //         // Continue with next book
  //       }
  //     }
  //   }

  //   logger.i('Parsed ${result.length} books');
  //   return result;
  // }

  // Future<Uint8List?> fetchImageWithAuth(
  //   int bookId,
  //   CoverResolution resolution,
  // ) async {
  //   return _apiService.fetchImage(
  //     '/cover/$bookId/$resolution',
  //     AuthMethod.cookie,
  //   );
  // }
}
