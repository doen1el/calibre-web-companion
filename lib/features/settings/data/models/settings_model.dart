import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';

class SettingsModel extends Equatable {
  final ThemeMode themeMode;
  final ThemeSource themeSource;
  final String selectedColorKey;
  final bool isDownloaderEnabled;
  final String downloaderUrl;
  final String downloaderUsername;
  final String downloaderPassword;
  final bool isSend2ereaderEnabled;
  final String send2ereaderUrl;
  final String defaultDownloadPath;
  final DownloadSchema downloadSchema;
  final String languageCode;
  final bool showReadNowButton;

  const SettingsModel({
    required this.themeMode,
    required this.themeSource,
    required this.selectedColorKey,
    required this.isDownloaderEnabled,
    required this.downloaderUrl,
    required this.downloaderUsername,
    required this.downloaderPassword,
    required this.isSend2ereaderEnabled,
    required this.send2ereaderUrl,
    required this.defaultDownloadPath,
    required this.downloadSchema,
    required this.languageCode,
    required this.showReadNowButton,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: ThemeMode.values[json['theme_mode'] ?? 0],
      themeSource: ThemeSource.values[json['theme_source'] ?? 0],
      selectedColorKey: json['theme_color_key'] ?? 'lightGreen',
      isDownloaderEnabled: json['downloader_enabled'] ?? false,
      downloaderUrl: json['downloader_url'] ?? '',
      downloaderUsername: json['downloader_username'] ?? '',
      downloaderPassword: json['downloader_password'] ?? '',
      isSend2ereaderEnabled: json['send2ereader_enabled'] ?? false,
      send2ereaderUrl: json['send2ereader_url'] ?? 'https://send.djazz.se',
      defaultDownloadPath: json['default_download_path'] ?? '',
      downloadSchema: DownloadSchema.values[json['download_schema'] ?? 0],
      languageCode: json['language_code'] ?? 'en',
      showReadNowButton: json['show_read_now_button'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    themeSource,
    selectedColorKey,
    isDownloaderEnabled,
    downloaderUrl,
    downloaderUsername,
    downloaderPassword,
    isSend2ereaderEnabled,
    send2ereaderUrl,
    defaultDownloadPath,
    downloadSchema,
    languageCode,
    showReadNowButton,
  ];
}
