import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/settings/data/models/predefined_colors.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SettingsStatus { initial, loading, loaded, error }

enum SettingsFeedbackStatus { initial, loading, success, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final SettingsFeedbackStatus feedbackStatus;
  final ThemeMode themeMode;
  final ThemeSource themeSource;
  final String selectedColorKey;
  final bool isDownloaderEnabled;
  final String downloaderUrl;
  final bool isSend2ereaderEnabled;
  final String send2ereaderUrl;
  final String defaultDownloadPath;
  final DownloadSchema downloadSchema;
  final String? errorMessage;
  final String? appVersion;
  final String? buildNumber;
  final String? feedbackTitle;
  final String? feedbackDescription;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.feedbackStatus = SettingsFeedbackStatus.initial,
    this.themeMode = ThemeMode.system,
    this.themeSource = ThemeSource.custom,
    this.selectedColorKey = 'lightGreen',
    this.isDownloaderEnabled = false,
    this.downloaderUrl = '',
    this.isSend2ereaderEnabled = false,
    this.send2ereaderUrl = 'https://send.djazz.se/',
    this.defaultDownloadPath = '',
    this.downloadSchema = DownloadSchema.flat,
    this.errorMessage,
    this.appVersion,
    this.buildNumber,
    this.feedbackTitle,
    this.feedbackDescription,
  });

  MaterialColor get selectedColor =>
      PredefinedColors.predefinedColors[selectedColorKey] ?? Colors.lightGreen;

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsFeedbackStatus? feedbackStatus,
    ThemeMode? themeMode,
    ThemeSource? themeSource,
    String? selectedColorKey,
    bool? isDownloaderEnabled,
    String? downloaderUrl,
    bool? isSend2ereaderEnabled,
    String? send2ereaderUrl,
    String? defaultDownloadPath,
    DownloadSchema? downloadSchema,
    String? errorMessage,
    String? appVersion,
    String? buildNumber,
    String? feedbackTitle,
    String? feedbackDescription,
  }) {
    return SettingsState(
      status: status ?? this.status,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      themeMode: themeMode ?? this.themeMode,
      themeSource: themeSource ?? this.themeSource,
      selectedColorKey: selectedColorKey ?? this.selectedColorKey,
      isDownloaderEnabled: isDownloaderEnabled ?? this.isDownloaderEnabled,
      downloaderUrl: downloaderUrl ?? this.downloaderUrl,
      isSend2ereaderEnabled:
          isSend2ereaderEnabled ?? this.isSend2ereaderEnabled,
      send2ereaderUrl: send2ereaderUrl ?? this.send2ereaderUrl,
      defaultDownloadPath: defaultDownloadPath ?? this.defaultDownloadPath,
      downloadSchema: downloadSchema ?? this.downloadSchema,
      errorMessage: errorMessage,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      feedbackTitle: feedbackTitle ?? this.feedbackTitle,
      feedbackDescription: feedbackDescription ?? this.feedbackDescription,
    );
  }

  @override
  List<Object?> get props => [
    status,
    feedbackStatus,
    themeMode,
    themeSource,
    selectedColorKey,
    isDownloaderEnabled,
    downloaderUrl,
    isSend2ereaderEnabled,
    send2ereaderUrl,
    defaultDownloadPath,
    downloadSchema,
    errorMessage,
    appVersion,
    buildNumber,
    feedbackTitle,
    feedbackDescription,
  ];
}
