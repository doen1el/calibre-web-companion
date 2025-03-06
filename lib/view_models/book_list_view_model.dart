import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/opds_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

enum BookListType {
  bookmarked,
  unreadbooks,
  readbooks,
  hot,
  newlyAdded,
  rated,
  discover,
}

enum CategoryType {
  category,
  language,
  publisher,
  author,
  ratings,
  formats,
  series,
}

class BookListViewModel extends ChangeNotifier {
  final OpdsService _opdsService = OpdsService();
  final Logger _logger = Logger();

  bool isLoading = false;
  String? errorMessage;
  bool hasError = false;

  OpdsFeed<BookItem>? bookFeed;
  OpdsFeed<CategoryItem>? categoryFeed;

  /// Load books for a specific type
  ///
  /// Parameters:
  ///
  /// - `type`: The type of books to load
  /// - `subPath`: The subpath to load books from
  Future<void> loadBooks(BookListType type, {String? subPath}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getBookFeed(type, subPath: subPath);
      bookFeed = feed;
      categoryFeed = null;
      _logger.i("Loaded ${feed.items.length} books for ${type.name}");
    } catch (e) {
      _logger.e("Error loading books for ${type.name}: $e");
      errorMessage = "Failed to load books: $e";
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories for a specific type
  ///
  /// Parameters:
  ///
  /// - `type`: The type of categories to load
  /// - `subPath`: The subpath to load categories from
  Future<void> loadCategories(CategoryType type, {String? subPath}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getCategoryFeed(type, subPath: subPath);
      categoryFeed = feed;
      bookFeed = null;
      _logger.i("Loaded ${feed.items.length} categories for ${type.name}");
    } catch (e) {
      _logger.e("Error loading categories for ${type.name}: $e");
      errorMessage = "Failed to load categories: $e";
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reset the view model
  void reset() {
    bookFeed = null;
    categoryFeed = null;
    errorMessage = null;
    hasError = false;
    notifyListeners();
  }

  /// Load books from a specific path
  ///
  /// Parameters:
  ///
  /// - `fullPath`: The full path to load books from
  Future<void> loadBooksFromPath(String fullPath) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getBooksFromPath(fullPath);
      bookFeed = feed;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading books from path: $e');
      errorMessage = 'Error loading books from path: $e';
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }
}
