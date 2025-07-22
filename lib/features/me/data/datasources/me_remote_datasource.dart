import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';

class MeRemoteDataSource {
  final ApiService apiService;
  final SharedPreferences preferences;

  MeRemoteDataSource({required this.apiService, required this.preferences});

  Future<StatsModel> getStats() async {
    try {
      final jsonData = await apiService.getJson(
        endpoint: '/opds/stats',
        authMethod: AuthMethod.auto,
      );
      return StatsModel.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await apiService.get(endpoint: '/logout', authMethod: AuthMethod.cookie);
      await preferences.remove('base_url');
      await preferences.remove('username');
      await preferences.remove('password');
      await preferences.remove('calibre_web_session');
      await apiService.reset();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}
