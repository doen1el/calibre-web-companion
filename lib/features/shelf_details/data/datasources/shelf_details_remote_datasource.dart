import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';

class ShelfDetailsRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  ShelfDetailsRemoteDataSource({
    required this.apiService,
    required this.logger,
  });

  Future<ShelfDetailsModel> getShelfDetails(String shelfId) async {
    try {
      final res = await apiService.getXmlAsJson(
        endpoint: '/opds/shelf/$shelfId',
        authMethod: AuthMethod.auto,
      );
      return ShelfDetailsModel.fromFeedJson(res);
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

  Future<bool> editShelf(
    String shelfId,
    String newShelfName, {
    bool isPublic = false,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/edit/$shelfId',
        authMethod: AuthMethod.cookie,
        body: {'title': newShelfName, if (isPublic) 'is_public': 'on'},
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
}
