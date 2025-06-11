import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';

class MeDataSource {
  final ApiService apiService;

  MeDataSource({required this.apiService});

  Future<StatsModel> getStats() async {
    try {
      final jsonData = await apiService.getJson(
        '/opds/stats',
        AuthMethod.basic,
      );
      return StatsModel.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await apiService.get('/logout', AuthMethod.cookie);
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}
