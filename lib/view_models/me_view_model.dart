import 'package:calibre_web_companion/models/stats_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class MeViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Logger logger = Logger();
  bool isLoading = false;
  StatsModel? stats;
  String? errorMessage;

  Future<StatsModel> getStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final jsonData = await _apiService.getJson(
        '/opds/stats',
        AuthMethod.basic,
      );

      final statsModel = StatsModel.fromJson(jsonData);
      stats = statsModel;
      logger.i("Stats loaded: $statsModel");
      isLoading = false;
      notifyListeners();
      return statsModel;
    } catch (e) {
      logger.e('Error loading stats: $e');
      errorMessage = 'Error: $e';
      isLoading = false;
      notifyListeners();
      return StatsModel();
    }
  }
}
