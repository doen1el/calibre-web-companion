import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';

class ShelfDetailsDataSource {
  final ApiService apiService;
  final Logger _logger = Logger();

  ShelfDetailsDataSource({required this.apiService});

  Future<ShelfDetailsModel> getShelfDetails(String shelfId) async {
    try {
      final path = '/shelf/$shelfId';
      final response = await apiService.get(path, AuthMethod.cookie);

      if (response.statusCode == 200) {
        return ShelfDetailsModel.fromHtml(response.body);
      } else {
        throw Exception('Failed to get shelf details: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting shelf details: $e');
      throw Exception('Failed to get shelf details: $e');
    }
  }

  Future<bool> removeFromShelf(String shelfId, String bookId) async {
    try {
      final response = await apiService.post(
        '/shelf/remove/$shelfId/$bookId',
        {},
        {},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 204;
    } catch (e) {
      _logger.e('Error removing from shelf: $e');
      throw Exception('Failed to remove from shelf: $e');
    }
  }

  Future<bool> createShelf(String shelfName) async {
    try {
      final response = await apiService.post(
        '/shelf/create',
        {},
        {'title': shelfName},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      _logger.e('Error creating shelf: $e');
      throw Exception('Failed to create shelf: $e');
    }
  }

  Future<bool> editShelf(String shelfId, String newShelfName) async {
    try {
      final response = await apiService.post(
        '/shelf/edit/$shelfId',
        {},
        {'title': newShelfName},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      _logger.e('Error editing shelf: $e');
      throw Exception('Failed to edit shelf: $e');
    }
  }

  Future<bool> deleteShelf(String shelfId) async {
    try {
      final response = await apiService.post(
        '/shelf/delete/$shelfId',
        {},
        {},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      return response.statusCode == 302;
    } catch (e) {
      _logger.e('Error deleting shelf: $e');
      throw Exception('Failed to delete shelf: $e');
    }
  }
}
