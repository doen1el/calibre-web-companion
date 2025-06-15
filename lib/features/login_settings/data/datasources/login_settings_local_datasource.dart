import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsLocalDataSource {
  final SharedPreferences preferences;
  final Logger logger;

  LoginSettingsLocalDataSource({
    required this.preferences,
    required this.logger,
  });

  static const String _customHeadersKey = 'custom_login_headers';

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
      final List<Map<String, dynamic>> jsonList =
          headers.map((header) => {header.key: header.value}).toList();

      final String jsonString = json.encode(jsonList);
      await preferences.setString(_customHeadersKey, jsonString);

      logger.i('Saved headers: $jsonList');
    } catch (e) {
      logger.e('Error saving headers: $e');
      throw Exception('Failed to save headers: $e');
    }
  }
}
