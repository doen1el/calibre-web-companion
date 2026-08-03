import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService {
  final ApiService apiService;
  final Connectivity _connectivity;

  ConnectivityService({required this.apiService, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  Stream<List<ConnectivityResult>> get onChange =>
      _connectivity.onConnectivityChanged;

  Future<bool> hasNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<bool> isServerReachable() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) return false;

      final baseUrl = apiService.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      return await apiService.isReachable(endpoint: await _probeEndpoint());
    } catch (_) {
      return false;
    }
  }

  Future<String> _probeEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString('reachability_probe_endpoint')?.trim();
    if (override != null && override.isNotEmpty) return override;

    switch (prefs.getString('server_type')) {
      case 'calibre':
        return '/ajax/library-info';
      case 'grimmory':
        return '/catalog';
      case 'opds':
        return '';
      default:
        return '/ajax/listbooks?limit=1';
    }
  }
}
