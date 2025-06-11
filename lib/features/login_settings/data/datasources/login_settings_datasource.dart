import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsDatasource {
  final SharedPreferences _preferences;
  final Logger _logger = Logger();

  LoginSettingsDatasource({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _customHeadersKey = 'custom_login_headers';

  Future<List<CustomHeaderModel>> getCustomHeaders() async {
    try {
      final String jsonString =
          _preferences.getString(_customHeadersKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonString);

      _logger.i('Loaded headers: $jsonList');
      return CustomHeaderModel.fromJsonList(jsonList);
    } catch (e) {
      _logger.e('Error loading headers: $e');
      return [];
    }
  }

  Future<void> saveCustomHeaders(List<CustomHeaderModel> headers) async {
    try {
      final List<Map<String, dynamic>> jsonList =
          headers.map((header) => {header.key: header.value}).toList();

      final String jsonString = json.encode(jsonList);
      await _preferences.setString(_customHeadersKey, jsonString);

      _logger.i('Saved headers: $jsonList');
    } catch (e) {
      _logger.e('Error saving headers: $e');
      throw Exception('Failed to save headers: $e');
    }
  }
}
