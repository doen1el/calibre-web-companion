import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class CancellationToken {
  bool _isCancelled = false;

  void cancel() => _isCancelled = true;
  bool get isCancelled => _isCancelled;
}

class BookViewRemoteDatasource {
  final ApiService _apiService;
  final Logger _logger;
  final SharedPreferences _preferences;

  BookViewRemoteDatasource({
    required SharedPreferences preferences,
    ApiService? apiService,
    Logger? logger,
  }) : _preferences = preferences,
       _apiService = apiService ?? ApiService(),
       _logger = logger ?? Logger();

  Future<List<BookViewModel>> fetchBooks({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async {
    try {
      List<BookViewModel> books = [];

      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sortBy,
        'order': sortOrder,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _apiService.getJson(
        endpoint: '/ajax/listbooks',
        authMethod: AuthMethod.cookie,
        queryParams: queryParams,
      );

      if (response.containsKey('rows') && response['rows'] is List) {
        final List<dynamic> rows = response['rows'];
        if (rows.isEmpty) {
          _logger.i('Received empty book list');
          return books;
        }
        for (var bookData in rows) {
          try {
            final book = BookViewModel.fromJson(bookData);

            books.add(book);
          } catch (e) {
            _logger.e('Error parsing book: $e');
          }
        }
        _logger.i('Parsed ${books.length} books');
        return books;
      }
      throw Exception('Invalid response format: $response');
    } catch (e) {
      _logger.e('Error fetching books: $e');
      throw Exception('Failed to load books: $e');
    }
  }

  Future<bool> uploadEbook(File book, CancellationToken cancelToken) async {
    try {
      final result = await _apiService.uploadFile(
        file: book,
        endpoint: '/upload',
        cancelToken: cancelToken,
        timeoutSeconds: 60,
      );

      if (result['cancelled'] == true) {
        _logger.i('Upload was cancelled');
        return false;
      }

      if (result['success'] == true) {
        return true;
      } else {
        _logger.e('Upload failed: ${result['error']}');
        throw Exception(result['error']);
      }
    } catch (e) {
      _logger.e('Error uploading book: $e');
      if (!cancelToken.isCancelled) {
        throw Exception('Upload error: $e');
      }
      return false;
    }
  }

  Future<int> getColumnCount() async {
    return _preferences.getInt('grid_column_count') ?? 2;
  }

  Future<void> setColumnCount(int count) async {
    if (count < 1) count = 1;
    if (count > 5) count = 5;
    await _preferences.setInt('grid_column_count', count);
  }
}
