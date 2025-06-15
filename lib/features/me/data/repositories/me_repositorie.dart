import 'package:calibre_web_companion/features/me/data/datasources/me_remote_datasource.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';

class MeRepository {
  final MeRemoteDataSource dataSource;

  MeRepository({required this.dataSource});

  Future<StatsModel> getStats() async {
    try {
      final stats = await dataSource.getStats();
      return stats;
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await dataSource.logOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}
