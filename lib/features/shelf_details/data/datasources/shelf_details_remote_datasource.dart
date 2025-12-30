import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEU

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';

class ShelfDetailsRemoteDataSource {
  final ApiService apiService;
  final Logger logger;
  final SharedPreferences preferences;

  ShelfDetailsRemoteDataSource({
    required this.apiService,
    required this.logger,
    required this.preferences,
  });

  Future<ShelfDetailsModel> getShelfDetails(String shelfId) async {
    try {
      final serverType = preferences.getString('server_type');

      if (serverType == 'opds') {
        return _getOpdsShelfDetails(shelfId);
      }

      final response = await apiService.getJson(
        endpoint: '/opds/shelf/$shelfId',
        authMethod: AuthMethod.auto,
      );

      return ShelfDetailsModel.fromFeedJson(response);
    } catch (e) {
      logger.e('Error fetching shelf details: $e');
      throw Exception('Failed to load shelf details: $e');
    }
  }

  Future<ShelfDetailsModel> _getOpdsShelfDetails(String shelfId) async {
    final response = await apiService.getXmlAsJson(
      endpoint: '/api/v1/opds/catalog',
      authMethod: AuthMethod.basic,
      queryParams: {'shelfId': shelfId},
    );

    return ShelfDetailsModel.fromFeedJson(response);
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

  bool getIsOpds() {
    return preferences.getString('server_type') == 'opds';
  }
}
