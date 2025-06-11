import 'dart:io';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookViewRepository {
  final BookViewDatasource _datasource;
  final Logger _logger;

  BookViewRepository({required BookViewDatasource datasource, Logger? logger})
    : _datasource = datasource,
      _logger = logger ?? Logger();

  Future<List<BookViewModel>> fetchBooks({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async {
    try {
      return await _datasource.fetchBooks(
        offset: offset,
        limit: limit,
        searchQuery: searchQuery,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _logger.e('Repository error fetching books: $e');
      rethrow;
    }
  }

  Future<bool> uploadEbook(File book) async {
    try {
      final cancelToken = CancellationToken();
      return await _datasource.uploadEbook(book, cancelToken);
    } catch (e) {
      _logger.e('Repository error uploading book: $e');
      rethrow;
    }
  }

  Future<int> getColumnCount() async {
    return await _datasource.getColumnCount();
  }

  Future<void> setColumnCount(int count) async {
    await _datasource.setColumnCount(count);
  }
}
