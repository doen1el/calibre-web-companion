import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_local_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';

class LoginSettingsRepository {
  final LoginSettingsLocalDataSource loginSettingsLocalDataSource;
  final Logger logger;

  LoginSettingsRepository({
    required this.loginSettingsLocalDataSource,
    required this.logger,
  });

  Future<List<CustomHeaderModel>> getCustomHeaders() async {
    try {
      final headers = await loginSettingsLocalDataSource.getCustomHeaders();
      return headers;
    } catch (e) {
      logger.e('Error getting custom headers: $e');
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

      await loginSettingsLocalDataSource.saveCustomHeaders(headerModels);
    } catch (e) {
      logger.e('Error saving custom headers: $e');
      throw Exception('Failed to save custom headers: $e');
    }
  }
}
