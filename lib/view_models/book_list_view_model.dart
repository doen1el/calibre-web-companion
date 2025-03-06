import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/opds_service.dart';
import 'package:calibre_web_companion/views/book_list.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class BookListViewModel extends ChangeNotifier {
  final OpdsService _opdsService = OpdsService();
  final Logger _logger = Logger();

  bool isLoading = false;
  String? errorMessage;

  OpdsFeed<BookItem>? bookFeed;
  OpdsFeed<CategoryItem>? categoryFeed;

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
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    bookFeed = null;
    categoryFeed = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Lädt Bücher von einem vollständigen OPDS-Pfad
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
      errorMessage = 'Fehler beim Laden der Bücher: $e';
      isLoading = false;
      notifyListeners();
    }
  }
}
