import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsRepository {
  final LoginSettingsDatasource _loginSettingsDatasource;
  final Logger _logger = Logger();

  LoginSettingsRepository({LoginSettingsDatasource? loginSettingsDatasource})
    : _loginSettingsDatasource =
          loginSettingsDatasource ??
          LoginSettingsDatasource(
            preferences: SharedPreferences.getInstance() as SharedPreferences,
          );

  Future<List<CustomHeaderModel>> getCustomHeaders() async {
    try {
      final headers = await _loginSettingsDatasource.getCustomHeaders();
      return headers;
    } catch (e) {
      _logger.e('Error getting custom headers: $e');
      return [];
    }
  }

  Future<void> saveCustomHeaders(List<CustomHeaderModel> headers) async {
    try {
      final headerModels =
          headers
              .map(
                (header) =>
                    CustomHeaderModel(key: header.key, value: header.value),
              )
              .toList();

      await _loginSettingsDatasource.saveCustomHeaders(headerModels);
    } catch (e) {
      _logger.e('Error saving custom headers: $e');
      throw Exception('Failed to save custom headers: $e');
    }
  }
}
