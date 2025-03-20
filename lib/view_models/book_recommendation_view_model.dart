import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/book_recommendation_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class BookRecommendationsViewModel extends ChangeNotifier {
  final BookRecommendationService _recommendationService =
      BookRecommendationService();
  final Logger logger = Logger();

  List<BookItem> _userBooks = [];
  BookItem? _selectedBook;
  List<BookRecommendation> _recommendations = [];
  bool _isLoadingBooks = false;
  bool _isLoadingRecommendations = false;
  String _error = '';

  // Getters
  List<BookItem> get userBooks => _userBooks;
  BookItem? get selectedBook => _selectedBook;
  List<BookRecommendation> get recommendations => _recommendations;
  bool get isLoadingBooks => _isLoadingBooks;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String get error => _error;
  bool get hasBooks => _userBooks.isNotEmpty;

  // Setters
  set selectedBook(BookItem? book) {
    _selectedBook = book;
    if (book != null) {
      loadRecommendationsForBook(book);
    } else {
      _recommendations = [];
    }
    notifyListeners();
  }

  /// Get all books that have been read
  Future<void> loadUserBooks() async {
    _isLoadingBooks = true;
    _error = '';
    _selectedBook = null;
    notifyListeners();

    try {
      BookListViewModel bookListViewModel = BookListViewModel();

      await bookListViewModel.loadBooks(BookListType.readbooks);

      _userBooks = bookListViewModel.bookFeed?.items ?? [];
      _userBooks.sort((a, b) => a.title.compareTo(b.title));

      if (_userBooks.isEmpty) {
        _error = 'No books found.';
      }
    } catch (e) {
      _error = 'Error loading books: $e';
      logger.e(_error);
    } finally {
      _isLoadingBooks = false;
      notifyListeners();
    }
  }

  /// Load recommendations for a book
  ///
  /// Parameters:
  ///
  /// - `book`: BookItem
  Future<void> loadRecommendationsForBook(BookItem book) async {
    _isLoadingRecommendations = true;
    _recommendations = [];
    _error = '';
    notifyListeners();

    try {
      final searchResults = await _recommendationService.searchBook(book.title);

      final matchingBooks =
          searchResults.where((result) => result.type == 'book').toList()
            ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

      if (matchingBooks.isEmpty) {
        _error = 'No hit for "${book.title}".';
        notifyListeners();
        return;
      }

      final bestMatch = matchingBooks.first;

      logger.i(
        'Best match for "${book.title}": ${bestMatch.line1} (Score: ${bestMatch.score})',
      );

      _recommendations = await _recommendationService.getRecommendations(
        bestMatch,
      );

      if (_recommendations.isEmpty) {
        _error = 'No recommendation for "${book.title}".';
      }
    } catch (e) {
      _error = 'Error loading recommendation: $e';
      logger.e(_error);
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }
}
