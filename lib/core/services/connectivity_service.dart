import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';

class ConnectivityService {
  final ApiService apiService;
  final Connectivity _connectivity;

  ConnectivityService({required this.apiService, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  Stream<List<ConnectivityResult>> get onChange =>
      _connectivity.onConnectivityChanged;

  Future<bool> isServerReachable() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) return false;

      final baseUrl = apiService.getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final response = await apiService
          .get(endpoint: '/', authMethod: AuthMethod.none)
          .timeout(const Duration(seconds: 6));
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }
}
