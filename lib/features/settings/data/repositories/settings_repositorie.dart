import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:calibre_web_companion/features/settings/data/models/settings_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

class SettingsRepositorie {
  final SettingsLocalDataSource dataSource;

  SettingsRepositorie({required this.dataSource});

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
}
