import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';

class MeRemoteDataSource {
  final ApiService apiService;
  final SharedPreferences preferences;

  MeRemoteDataSource({required this.apiService, required this.preferences});

  Future<StatsModel> getStats() async {
    try {
      final serverType = preferences.getString('server_type');

      if (serverType == 'opds') {
        return _getOpdsStats();
      }

      final jsonData = await apiService.getJson(
        endpoint: '/opds/stats',
        authMethod: AuthMethod.auto,
      );
      return StatsModel.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<StatsModel> _getOpdsStats() async {
    final json = await apiService.getXmlAsJson(
      endpoint: '/catalog',
      authMethod: AuthMethod.basic,
      queryParams: {'page': '1', 'size': '1'},
    );

    int totalBooks = 0;

    if (json.containsKey('feed')) {
      final feed = json['feed'];
      if (feed is Map) {
        if (feed.containsKey('opensearch:totalResults')) {
          totalBooks =
              int.tryParse(feed['opensearch:totalResults'].toString()) ?? 0;
        } else if (feed.containsKey('totalResults')) {
          totalBooks = int.tryParse(feed['totalResults'].toString()) ?? 0;
        }
      }
    }

    return StatsModel(books: totalBooks);
  }

  Future<void> logOut() async {
    try {
      final serverType = preferences.getString('server_type');

      if (serverType != 'opds') {
        try {
          await apiService.get(
            endpoint: '/logout',
            authMethod: AuthMethod.cookie,
          );
        } catch (e) {
          throw Exception('Failed to logout from server: $e');
        }
      }

      await preferences.remove('base_url');
      await preferences.remove('username');
      await preferences.remove('password');
      await preferences.remove('calibre_web_session');
      await preferences.remove('server_type');

      await apiService.reset();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  bool getIsOpds() {
    return preferences.getString('server_type') == 'opds';
  }
}
