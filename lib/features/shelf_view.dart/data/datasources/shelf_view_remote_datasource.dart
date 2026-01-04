import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';

class ShelfViewRemoteDataSource {
  final ApiService apiService;
  final Logger logger;
  final ShelfDetailsRemoteDataSource shelfDetailsRemoteDataSource;
  final SharedPreferences preferences;

  ShelfViewRemoteDataSource({
    required this.apiService,
    required this.logger,
    required this.shelfDetailsRemoteDataSource,
    required this.preferences,
  });

  Future<ShelfListViewModel> loadShelves() async {
    try {
      final serverType = preferences.getString('server_type');

      if (serverType == 'opds' || serverType == 'booklore') {
        return _loadOpdsShelves();
      }

      final res = await apiService.getXmlAsJson(
        endpoint: '/opds/shelfindex',
        authMethod: AuthMethod.auto,
      );
      return ShelfListViewModel.fromFeedJson(res);
    } catch (e) {
      logger.e("Error loading shelves: $e");
      throw Exception('Failed to load shelves: $e');
    }
  }

  Future<ShelfListViewModel> _loadOpdsShelves() async {
    final res = await apiService.getXmlAsJson(
      endpoint: '/shelves',
      authMethod: AuthMethod.basic,
    );
    return ShelfListViewModel.fromFeedJson(res);
  }

  Future<String> createShelf(String shelfName, {bool isPublic = false}) async {
    try {
      final Map<String, dynamic> body = {'title': shelfName};
      if (isPublic) {
        body['is_public'] = 'on';
      }

      final response = await apiService.post(
        endpoint: '/shelf/create',
        authMethod: AuthMethod.cookie,
        body: body,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode != 302) {
        logger.e('Failed to create shelf: ${response.body}');
        throw Exception('Failed to create shelf: ${response.body}');
      }

      final shelfId = response.headers['location']!.split('/').last;

      return shelfId;
    } catch (e) {
      logger.e('Error creating shelf: $e');
      throw Exception('Failed to create shelf: $e');
    }
  }

  Future<void> removeBookFromShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/remove/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode != 204) {
        logger.e('Failed to remove book from shelf: ${response.body}');
        throw Exception('Failed to remove book from shelf: ${response.body}');
      }
    } catch (e) {
      logger.e('Error removing book from shelf: $e');
      throw Exception('Failed to remove book from shelf: $e');
    }
  }

  Future<void> addBookToShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/add/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode != 204) {
        logger.e('Failed to add book to shelf: ${response.body}');
        throw Exception('Failed to add book to shelf: ${response.body}');
      }
    } catch (e) {
      logger.e('Error adding book to shelf: $e');
      throw Exception('Failed to add book to shelf: $e');
    }
  }

  Future<List<ShelfViewModel>> findShelvesContainingBook(String bookId) async {
    try {
      List<ShelfViewModel> shelves = [];
      ShelfListViewModel shelf = await loadShelves();

      for (var s in shelf.shelves) {
        final ShelfDetailsModel shelfDetails =
            await shelfDetailsRemoteDataSource.getShelfDetails(s.id);

        for (var book in shelfDetails.books) {
          if (book.id == bookId) {
            logger.d('Found book in shelf: ${s.title}');
            shelves.add(ShelfViewModel(id: s.id, title: s.title));
          }
        }
      }

      return shelves;
    } catch (e) {
      logger.e('Error finding shelves containing book: $e');
      throw Exception('Failed to find shelves containing book: $e');
    }
  }

  bool getIsOpds() {
    return preferences.getString('server_type') == 'opds' ||
        preferences.getString('server_type') == 'booklore';
  }
}
