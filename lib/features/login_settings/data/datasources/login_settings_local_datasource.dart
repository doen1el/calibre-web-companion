import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

class LoginSettingsLocalDataSource {
  final SharedPreferences preferences;
  final Logger logger;
  final ApiService apiService;

  LoginSettingsLocalDataSource({
    required this.preferences,
    required this.logger,
    required this.apiService,
  });

  static const String _customHeadersKey = 'custom_login_headers';
  static const String _basePathKey = 'base_path';

  Future<List<CustomHeaderModel>> getCustomHeaders() async {
    try {
      final String jsonString =
          preferences.getString(_customHeadersKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);

      logger.i('Loaded headers: $jsonList');
      return CustomHeaderModel.fromJsonList(jsonList);
    } catch (e) {
      logger.e('Error loading headers: $e');
      return [];
    }
  }

  Future<void> saveCustomHeaders(List<CustomHeaderModel> headers) async {
    try {
      final validHeaders =
          headers.where((header) => header.key.trim().isNotEmpty).toList();

      final List<Map<String, dynamic>> jsonList =
          validHeaders.map((header) => header.toMap()).toList();

      final String jsonString = json.encode(jsonList);
      await preferences.setString(_customHeadersKey, jsonString);

      await apiService.initialize();

      logger.i('Saved ${validHeaders.length} headers');
    } catch (e) {
      logger.e('Error saving headers: $e');
      throw Exception('Failed to save headers: $e');
    }
  }

  Future<String> getBasePath() async {
    try {
      final String basePath = preferences.getString(_basePathKey) ?? '';
      logger.i('Loaded base path: $basePath');
      return basePath;
    } catch (e) {
      logger.e('Error loading base path: $e');
      return '';
    }
  }

  Future<void> saveBasePath(String basePath) async {
    try {
      await preferences.setString(_basePathKey, basePath);
      await apiService.initialize();
      logger.i('Saved base path: $basePath');
    } catch (e) {
      logger.e('Error saving base path: $e');
      throw Exception('Failed to save base path: $e');
    }
  }
}
