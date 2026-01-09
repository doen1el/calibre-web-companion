import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:calibre_web_companion/features/settings/data/models/settings_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';

class SettingsRepository {
  final SettingsLocalDataSource dataSource;

  SettingsRepository({required this.dataSource});

  Future<SettingsModel> getSettings() async {
    try {
      return await dataSource.getSettings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await dataSource.saveThemeMode(mode);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setThemeSource(ThemeSource source) async {
    try {
      await dataSource.saveThemeSource(source);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setSelectedColor(String colorKey) async {
    try {
      await dataSource.saveSelectedColor(colorKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDownloaderEnabled(bool enabled) async {
    try {
      await dataSource.saveDownloaderEnabled(enabled);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDownloaderUrl(String url) async {
    try {
      await dataSource.saveDownloaderUrl(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDownloaderCredentials(
    String username,
    String password,
  ) async {
    try {
      await dataSource.saveDownloaderCredentials(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setSend2ereaderEnabled(bool enabled) async {
    try {
      await dataSource.saveSend2ereaderEnabled(enabled);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setSend2ereaderUrl(String url) async {
    try {
      await dataSource.saveSend2ereaderUrl(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultDownloadPath(String path) async {
    try {
      await dataSource.saveDefaultDownloadPath(path);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDownloadSchema(DownloadSchema schema) async {
    try {
      await dataSource.saveDownloadSchema(schema);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitFeedback(String title, String description) async {
    try {
      return await dataSource.submitFeedback(title, description);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await dataSource.saveLanguage(language);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getLanguage() async {
    return await dataSource.getLanguage();
  }

  Future<void> setShowReadNowButton(bool enabled) async {
    try {
      await dataSource.saveShowReadNowButton(enabled);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> buyMeACoffee() async {
    try {
      return await dataSource.buyMeACoffe();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setWebDavSyncEnabled(bool enabled) async {
    try {
      await dataSource.saveWebDavSyncEnabled(enabled);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setWebDavUrl(String url) async {
    try {
      await dataSource.saveWebDavUrl(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setWebDavCredentials(String username, String password) async {
    try {
      await dataSource.saveWebDavCredentials(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> testDownloaderConnection(
    String url,
    String username,
    String password,
  ) async {
    try {
      final uri = Uri.parse('$url/api/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'remember_me': true,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Connection failed: $e");
    }
  }

  Future<bool> testWebDavConnection(
    String url,
    String username,
    String password,
  ) async {
    try {
      final service = WebDavSyncService(logger: Logger());
      service.init(url, username, password);
      await service.testConnection();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setEpubScrollDirection(String direction) async {
    try {
      await dataSource.saveEpubScrollDirection(direction);
    } catch (e) {
      rethrow;
    }
  }
}
