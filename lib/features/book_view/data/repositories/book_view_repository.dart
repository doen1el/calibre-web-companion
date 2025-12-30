import 'dart:io';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookViewRepository {
  final BookViewRemoteDatasource datasource;
  final Logger logger;

  BookViewRepository({required this.datasource, required this.logger});

  Future<List<BookViewModel>> fetchBooks({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async {
    try {
      return await datasource.fetchBooks(
        offset: offset,
        limit: limit,
        searchQuery: searchQuery,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      logger.e('Repository error fetching books: $e');
      rethrow;
    }
  }

  Future<bool> uploadEbook(File book) async {
    try {
      final cancelToken = CancellationToken();
      return await datasource.uploadEbook(book, cancelToken);
    } catch (e) {
      logger.e('Repository error uploading book: $e');
      rethrow;
    }
  }

  Future<int> getColumnCount() async {
    return await datasource.getColumnCount();
  }

  Future<void> setColumnCount(int count) async {
    await datasource.setColumnCount(count);
  }

  Future<bool> getIsListView() async {
    return await datasource.getIsListView();
  }

  Future<void> setIsListView(bool isList) async {
    await datasource.setIsListView(isList);
  }

  bool getIsOpds() => datasource.getIsOpds();
}
