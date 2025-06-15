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
}
