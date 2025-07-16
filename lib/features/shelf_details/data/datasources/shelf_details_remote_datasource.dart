import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class ShelfDetailsRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  ShelfDetailsRemoteDataSource({
    required this.apiService,
    required this.logger,
  });

  Future<ShelfDetailsModel> getShelfDetails(String shelfId) async {
    try {
      final path = '/shelf/$shelfId';
      final response = await apiService.get(
        endpoint: path,
        authMethod: AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        return ShelfDetailsModel.fromHtml(response.body);
      } else {
        throw Exception('Failed to get shelf details: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error getting shelf details: $e');
      throw Exception('Failed to get shelf details: $e');
    }
  }

  Future<bool> removeFromShelf(String shelfId, String bookId) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/remove/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 204;
    } catch (e) {
      logger.e('Error removing from shelf: $e');
      throw Exception('Failed to remove from shelf: $e');
    }
  }

  Future<bool> createShelf(String shelfName) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/create',
        authMethod: AuthMethod.cookie,
        body: {'title': shelfName},
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      logger.e('Error creating shelf: $e');
      throw Exception('Failed to create shelf: $e');
    }
  }

  Future<bool> editShelf(String shelfId, String newShelfName) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/edit/$shelfId',
        authMethod: AuthMethod.cookie,
        body: {'title': newShelfName},
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      logger.e('Error editing shelf: $e');
      throw Exception('Failed to edit shelf: $e');
    }
  }

  Future<bool> deleteShelf(String shelfId) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/delete/$shelfId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      logger.e('Error deleting shelf: $e');
      throw Exception('Failed to delete shelf: $e');
    }
  }

  Future<BookViewModel> loadBookDetails(String bookId) async {
    try {
      logger.i('Loading book details for bookId: $bookId');
      List<BookViewModel> books = [];
      bool foundBook = false;
      BookViewModel? targetBook;

      int targetBookId = int.tryParse(bookId)!;

      final int limit = 100;
      bool hasMoreBooks = true;

      while (hasMoreBooks && !foundBook) {
        final queryParams = {'limit': limit.toString(), 'order': 'asc'};

        logger.i('Loading books with limit $limit');

        final response = await apiService.getJson(
          endpoint: '/ajax/listbooks',
          authMethod: AuthMethod.cookie,
          queryParams: queryParams,
        );

        if (response.containsKey('rows') && response['rows'] is List) {
          final List<dynamic> rows = response['rows'];

          if (rows.isEmpty) {
            hasMoreBooks = false;
            logger.i('Received empty book list');
            break;
          }

          for (var bookData in rows) {
            try {
              final book = BookViewModel.fromJson(bookData);

              if (book.id == targetBookId) {
                targetBook = book;
                foundBook = true;
                logger.i('Found target book with id $bookId');
                break;
              }

              books.add(book);
            } catch (e) {
              logger.e('Error parsing book: $e');
            }
          }

          if (response.containsKey('total') && response.containsKey('page')) {
            final int total = response['total'];
            final int currentPage = response['page'];
            final int totalPages = (total / limit).ceil();

            hasMoreBooks = currentPage < totalPages;
            logger.i('Page $currentPage of $totalPages (total books: $total)');
          } else {
            hasMoreBooks = rows.length >= limit;
            logger.i('Loaded ${rows.length} books');
          }

          if (foundBook) break;
        } else {
          hasMoreBooks = false;
          logger.e('Invalid response format, missing "rows" array');
        }
      }

      if (targetBook != null) {
        return targetBook;
      } else {
        logger.e(
          'Book with id $bookId not found after loading ${books.length} books',
        );
        throw Exception('Book with ID $bookId not found');
      }
    } catch (e) {
      logger.e('Error loading book details: $e');
      throw Exception('Failed to load book details: $e');
    }
  }
}
