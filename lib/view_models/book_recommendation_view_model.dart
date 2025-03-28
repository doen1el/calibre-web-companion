import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/book_recommendation_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class BookRecommendationsViewModel extends ChangeNotifier {
  final BookRecommendationService _dbpediaService = BookRecommendationService();
  final Logger logger = Logger();

  List<BookItem> _userBooks = [];
  Map<String, List<String>> _bookSubjects = {};
  List<String> _allSubjects = [];
  bool _isLoadingBooks = false;
  bool _isLoadingSubjects = false;
  String _error = '';
  List<BookRecommendation> _recommendations = [];
  bool _isLoadingRecommendations = false;

  // Getters
  List<BookItem> get userBooks => _userBooks;
  Map<String, List<String>> get bookSubjects => _bookSubjects;
  List<String> get allSubjects => _allSubjects;
  bool get isLoadingBooks => _isLoadingBooks;
  bool get isLoadingSubjects => _isLoadingSubjects;
  String get error => _error;
  bool get hasBooks => _userBooks.isNotEmpty;
  bool get hasSubjects => _allSubjects.isNotEmpty;
  bool get hasRecommendations => _recommendations.isNotEmpty;
  List<BookRecommendation> get recommendations => _recommendations;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  /// Get all books that have been read
  Future<void> loadUserBooks() async {
    _isLoadingBooks = true;
    _error = '';
    notifyListeners();

    try {
      BookListViewModel bookListViewModel = BookListViewModel();
      await bookListViewModel.loadBooks(BookListType.readbooks);

      _userBooks = bookListViewModel.bookFeed?.items ?? [];
      _userBooks.sort((a, b) => a.title.compareTo(b.title));

      if (_userBooks.isEmpty) {
        _error = 'No books found.';
      } else {
        // Load subjects for all books
        await _loadSubjectsForAllBooks();
      }
    } catch (e) {
      _error = 'Error loading books: $e';
      logger.e(_error);
    } finally {
      _isLoadingBooks = false;
      notifyListeners();
    }
  }

  /// Load subjects for all read books from DBpedia
  Future<void> _loadSubjectsForAllBooks() async {
    _isLoadingSubjects = true;
    _bookSubjects = {};
    _allSubjects = []; // Initialisiere als leere Liste
    notifyListeners();

    try {
      int booksFound = 0;
      List<Map<String, dynamic>> dbpediaBooks = [];

      // First find all books in DBpedia
      for (var book in _userBooks) {
        try {
          final dbpediaBook = await _dbpediaService.findBookInDBpedia(
            book.title,
            book.author,
          );

          if (dbpediaBook != null &&
              dbpediaBook.containsKey('results') &&
              dbpediaBook['results']['bindings'].isNotEmpty) {
            final binding = dbpediaBook['results']['bindings'][0];
            if (binding.containsKey('book')) {
              dbpediaBooks.add(binding);
              booksFound++;
            }
          }
        } catch (e) {
          logger.w('Could not find book "${book.title}": $e');
        }
      }

      logger.i('Found $booksFound books in DBpedia');

      // Get subjects for individual books and collect all subjects
      for (var i = 0; i < _userBooks.length; i++) {
        final book = _userBooks[i];
        if (i < dbpediaBooks.length && dbpediaBooks[i].containsKey('book')) {
          final bookUri = dbpediaBooks[i]['book']['value'];
          final subjects = await _dbpediaService.getBookSubjects(bookUri);

          if (subjects.isNotEmpty) {
            // Speichere Subjects für das Buch
            _bookSubjects[book.id] = subjects;

            // Füge alle Subjects zur Gesamtliste hinzu
            _allSubjects.addAll(subjects);

            logger.i('Found ${subjects.length} subjects for "${book.title}"');
          }
        }
      }

      logger.i('Collected ${_allSubjects.length} subjects across all books');
    } catch (e) {
      _error = 'Error loading subjects: $e';
      logger.e(_error);
    } finally {
      _isLoadingSubjects = false;
      notifyListeners();
    }
  }

  /// Find book recommendations based on all collected subjects
  Future<void> findRecommendedBooks({int minimumMatches = 3}) async {
    _isLoadingRecommendations = true;
    _recommendations = [];
    notifyListeners();

    try {
      if (_allSubjects.isEmpty) {
        _error = 'No subjects found to base recommendations on';
        return;
      }

      // Get list of titles to exclude (books we've already read)
      final excludeTitles = _userBooks.map((book) => book.title).toList();

      // Find books matching our subjects
      _recommendations = await _dbpediaService.findBooksByMultipleSubjects(
        _allSubjects,
        minimumMatches: minimumMatches,
        excludeTitles: excludeTitles,
      );

      if (_recommendations.isEmpty) {
        _error =
            'No matching books found with $minimumMatches or more common subjects';
        logger.w(_error);
      } else {
        logger.i('Found ${_recommendations.length} book recommendations');
      }
    } catch (e) {
      _error = 'Error finding book recommendations: $e';
      logger.e(_error);
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }
}
