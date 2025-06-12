import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/settings/data/models/settings_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';

class SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;
  final Logger logger;

  SettingsLocalDataSource({
    required this.sharedPreferences,
    required this.logger,
  });

  Future<SettingsModel> getSettings() async {
    try {
      return SettingsModel.fromJson({
        'theme_mode': sharedPreferences.getInt('theme_mode') ?? 0,
        'theme_source': sharedPreferences.getInt('theme_source') ?? 0,
        'theme_color_key':
            sharedPreferences.getString('theme_color_key') ?? 'lightGreen',
        'downloader_enabled':
            sharedPreferences.getBool('downloader_enabled') ?? false,
        'downloader_url': sharedPreferences.getString('downloader_url') ?? '',
        'send2ereader_enabled':
            sharedPreferences.getBool('send2ereader_enabled') ?? false,
        'send2ereader_url':
            sharedPreferences.getString('send2ereader_url') ??
            'https://send.djazz.se/',
        'default_download_path':
            sharedPreferences.getString('default_download_path') ?? '',
        'download_schema': sharedPreferences.getInt('download_schema') ?? 0,
      });
    } catch (e) {
      logger.e('Error getting settings: $e');
      throw Exception('Failed to get settings: $e');
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await sharedPreferences.setInt('theme_mode', mode.index);
    } catch (e) {
      logger.e('Error saving theme mode: $e');
      throw Exception('Failed to save theme mode: $e');
    }
  }

  Future<void> saveThemeSource(ThemeSource source) async {
    try {
      await sharedPreferences.setInt('theme_source', source.index);
    } catch (e) {
      logger.e('Error saving theme source: $e');
      throw Exception('Failed to save theme source: $e');
    }
  }

  Future<void> saveSelectedColor(String colorKey) async {
    try {
      await sharedPreferences.setString('theme_color_key', colorKey);
    } catch (e) {
      logger.e('Error saving selected color: $e');
      throw Exception('Failed to save selected color: $e');
    }
  }

  Future<void> saveDownloaderEnabled(bool enabled) async {
    try {
      await sharedPreferences.setBool('downloader_enabled', enabled);
    } catch (e) {
      logger.e('Error saving downloader enabled: $e');
      throw Exception('Failed to save downloader enabled: $e');
    }
  }

  Future<void> saveDownloaderUrl(String url) async {
    try {
      await sharedPreferences.setString('downloader_url', url);
    } catch (e) {
      logger.e('Error saving downloader URL: $e');
      throw Exception('Failed to save downloader URL: $e');
    }
  }

  Future<void> saveSend2ereaderEnabled(bool enabled) async {
    try {
      await sharedPreferences.setBool('send2ereader_enabled', enabled);
    } catch (e) {
      logger.e('Error saving Send2Ereader enabled: $e');
      throw Exception('Failed to save Send2Ereader enabled: $e');
    }
  }

  Future<void> saveSend2ereaderUrl(String url) async {
    try {
      await sharedPreferences.setString('send2ereader_url', url);
    } catch (e) {
      logger.e('Error saving Send2Ereader URL: $e');
      throw Exception('Failed to save Send2Ereader URL: $e');
    }
  }

  Future<void> saveDefaultDownloadPath(String path) async {
    try {
      await sharedPreferences.setString('default_download_path', path);
    } catch (e) {
      logger.e('Error saving default download path: $e');
      throw Exception('Failed to save default download path: $e');
    }
  }

  Future<void> saveDownloadSchema(DownloadSchema schema) async {
    try {
      await sharedPreferences.setInt('download_schema', schema.index);
    } catch (e) {
      logger.e('Error saving download schema: $e');
      throw Exception('Failed to save download schema: $e');
    }
  }

  Future<void> submitFeedback(String title, String description) async {
    try {
      final githubToken = const String.fromEnvironment(
        'ISSUE_TOKEN',
        defaultValue: '',
      );

      final owner = 'doen1el';
      final repo = 'calibre-web-companion';

      await http.post(
        Uri.parse('https://api.github.com/repos/$owner/$repo/issues'),
        headers: {
          'Authorization': 'token $githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'title': title, 'body': description}),
      );
    } catch (e) {
      logger.e('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
