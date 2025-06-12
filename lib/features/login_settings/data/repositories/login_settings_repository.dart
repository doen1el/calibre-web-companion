import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsRepository {
  final LoginSettingsDatasource loginSettingsDatasource;
  final Logger _logger = Logger();

  LoginSettingsRepository({required this.loginSettingsDatasource});

  Future<List<CustomHeaderModel>> getCustomHeaders() async {
    try {
      final headers = await loginSettingsDatasource.getCustomHeaders();
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

      await loginSettingsDatasource.saveCustomHeaders(headerModels);
    } catch (e) {
      _logger.e('Error saving custom headers: $e');
      throw Exception('Failed to save custom headers: $e');
    }
  }
}
