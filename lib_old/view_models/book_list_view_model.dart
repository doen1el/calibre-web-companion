import '../models/opds_item_model.dart';
import '../utils/opds_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

enum discoverType {
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

  final Map<String, OpdsFeed<BookItem>> _bookFeedCache = {};
  final Map<String, OpdsFeed<CategoryItem>> _categoryFeedCache = {};

  /// Get the cache key for a specific type
  ///
  /// Parameters:
  ///
  /// - `type`: The type of books to load
  /// - `subPath`: The subpath to load books from
  String _getCacheKey(dynamic type, {String? subPath}) {
    return "${type.toString()}${subPath ?? ''}";
  }

  /// Load books for a specific type
  ///
  /// Parameters:
  ///
  /// - `type`: The type of books to load
  /// - `subPath`: The subpath to load books from
  Future<void> loadBooks(discoverType type, {String? subPath}) async {
    // Get the cache key
    final cacheKey = _getCacheKey(type, subPath: subPath);

    // Check if we have a cached version
    if (_bookFeedCache.containsKey(cacheKey)) {
      bookFeed = _bookFeedCache[cacheKey];
      categoryFeed = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getBookFeed(type, subPath: subPath);
      bookFeed = feed;
      // Cache the response
      _bookFeedCache[cacheKey] = feed;
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
    // Generate a cache key
    final cacheKey = _getCacheKey(type, subPath: subPath);

    // Check if we have a cached version
    if (_categoryFeedCache.containsKey(cacheKey)) {
      categoryFeed = _categoryFeedCache[cacheKey];
      bookFeed = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getCategoryFeed(type, subPath: subPath);
      categoryFeed = feed;
      // Cache the response
      _categoryFeedCache[cacheKey] = feed;
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
    // Use the path as cache key
    if (_bookFeedCache.containsKey(fullPath)) {
      bookFeed = _bookFeedCache[fullPath];
      categoryFeed = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final feed = await _opdsService.getBooksFromPath(fullPath);
      bookFeed = feed;
      // Cache the response
      _bookFeedCache[fullPath] = feed;
      categoryFeed = null;
      _logger.i("Loaded ${feed.items.length} books from path");
    } catch (e) {
      _logger.e("Error loading books from path: $e");
      errorMessage = "Failed to load books: $e";
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the cache
  void clearCache() {
    _bookFeedCache.clear();
    _categoryFeedCache.clear();
  }
}
