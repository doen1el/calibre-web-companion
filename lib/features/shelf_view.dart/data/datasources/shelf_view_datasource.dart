import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';

class ShelfViewDataSource {
  final ApiService apiService;
  final Logger _logger = Logger();

  ShelfViewDataSource({required this.apiService});

  Future<ShelfListViewModel> loadShelves() async {
    try {
      final res = await apiService.getXmlAsJson(
        '/opds/shelfindex',
        AuthMethod.basic,
      );
      return ShelfListViewModel.fromFeedJson(res);
    } catch (e) {
      _logger.e("Error loading shelves: $e");
      throw Exception('Failed to load shelves: $e');
    }
  }

  Future<String> createShelf(String shelfName) async {
    try {
      final response = await apiService.post(
        '/shelf/create',
        {},
        {'title': shelfName},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode != 302) {
        _logger.e('Failed to create shelf: ${response.body}');
        throw Exception('Failed to create shelf: ${response.body}');
      }

      final shelfId = response.headers['location']!.split('/').last;

      return shelfId;
    } catch (e) {
      _logger.e('Error creating shelf: $e');
      throw Exception('Failed to create shelf: $e');
    }
  }
}
