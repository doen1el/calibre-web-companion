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
      rethrow;
    }
  }

  Future<String> getBasePath() async {
    try {
      return await loginSettingsLocalDataSource.getBasePath();
    } catch (e) {
      return '';
    }
  }

  Future<void> saveBasePath(String basePath) async {
    try {
      await loginSettingsLocalDataSource.saveBasePath(basePath);
    } catch (e) {
      rethrow;
    }
  }
}
