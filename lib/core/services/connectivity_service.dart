import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';

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

      return await apiService.isReachable();
    } catch (_) {
      return false;
    }
  }
}
