import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/settings/data/models/predefined_colors.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';

enum SettingsStatus { initial, loading, loaded, error }

enum SettingsFeedbackStatus { initial, loading, success, error }

enum ConnectionTestStatus { initial, loading, success, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final SettingsFeedbackStatus feedbackStatus;
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
  final String? errorMessage;
  final String? appVersion;
  final String? buildNumber;
  final String? languageCode;
  final bool showReadNowButton;
  final bool showSendToEReaderButton;
  final bool storeReadNowAndSendToEReaderOnDevice;
  final bool isWebDavSyncEnabled;
  final String webDavUrl;
  final String webDavUsername;
  final String webDavPassword;
  final String epubScrollDirection;
  final bool isEInkMode;
  final List<String> bookActionsOrder;
  final List<String> enabledBookActions;
  final List<String> bookDetailsSectionsOrder;
  final List<String> enabledBookDetailsSections;
  final List<String> discoverMainSectionsOrder;
  final List<String> enabledDiscoverMainSections;
  final List<String> discoverItemsOrder;
  final List<String> enabledDiscoverItems;
  final List<String> categoryItemsOrder;
  final List<String> enabledCategoryItems;

  final ConnectionTestStatus downloaderTestStatus;
  final ConnectionTestStatus webDavTestStatus;
  final String? testErrorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.feedbackStatus = SettingsFeedbackStatus.initial,
    this.themeMode = ThemeMode.system,
    this.themeSource = ThemeSource.custom,
    this.selectedColorKey = 'lightGreen',
    this.isDownloaderEnabled = false,
    this.downloaderUrl = '',
    this.downloaderUsername = '',
    this.downloaderPassword = '',
    this.isSend2ereaderEnabled = false,
    this.send2ereaderUrl = 'https://send.djazz.se',
    this.defaultDownloadPath = '',
    this.downloadSchema = DownloadSchema.flat,
    this.errorMessage,
    this.appVersion,
    this.buildNumber,
    this.languageCode = 'en',
    this.showReadNowButton = false,
    this.showSendToEReaderButton = true,
    this.storeReadNowAndSendToEReaderOnDevice = false,
    this.isWebDavSyncEnabled = false,
    this.webDavUrl = '',
    this.webDavUsername = '',
    this.webDavPassword = '',
    this.epubScrollDirection = 'vertical',
    this.isEInkMode = false,
    this.bookActionsOrder = const [],
    this.enabledBookActions = const [],
    this.bookDetailsSectionsOrder = const [],
    this.enabledBookDetailsSections = const [],
    this.discoverMainSectionsOrder = const [],
    this.enabledDiscoverMainSections = const [],
    this.discoverItemsOrder = const [],
    this.enabledDiscoverItems = const [],
    this.categoryItemsOrder = const [],
    this.enabledCategoryItems = const [],
    this.downloaderTestStatus = ConnectionTestStatus.initial,
    this.webDavTestStatus = ConnectionTestStatus.initial,
    this.testErrorMessage,
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
    String? downloaderUsername,
    String? downloaderPassword,
    bool? isSend2ereaderEnabled,
    String? send2ereaderUrl,
    String? defaultDownloadPath,
    DownloadSchema? downloadSchema,
    String? errorMessage,
    String? appVersion,
    String? buildNumber,
    String? languageCode,
    bool? showReadNowButton,
    bool? showSendToEReaderButton,
    bool? storeReadNowAndSendToEReaderOnDevice,
    bool? isWebDavSyncEnabled,
    String? webDavUrl,
    String? webDavUsername,
    String? webDavPassword,
    String? epubScrollDirection,
    bool? isEInkMode,
    List<String>? bookActionsOrder,
    List<String>? enabledBookActions,
    List<String>? bookDetailsSectionsOrder,
    List<String>? enabledBookDetailsSections,
    List<String>? discoverMainSectionsOrder,
    List<String>? enabledDiscoverMainSections,
    List<String>? discoverItemsOrder,
    List<String>? enabledDiscoverItems,
    List<String>? categoryItemsOrder,
    List<String>? enabledCategoryItems,
    ConnectionTestStatus? downloaderTestStatus,
    ConnectionTestStatus? webDavTestStatus,
    String? testErrorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      themeMode: themeMode ?? this.themeMode,
      themeSource: themeSource ?? this.themeSource,
      selectedColorKey: selectedColorKey ?? this.selectedColorKey,
      isDownloaderEnabled: isDownloaderEnabled ?? this.isDownloaderEnabled,
      downloaderUrl: downloaderUrl ?? this.downloaderUrl,
      downloaderUsername: downloaderUsername ?? this.downloaderUsername,
      downloaderPassword: downloaderPassword ?? this.downloaderPassword,
      isSend2ereaderEnabled:
          isSend2ereaderEnabled ?? this.isSend2ereaderEnabled,
      send2ereaderUrl: send2ereaderUrl ?? this.send2ereaderUrl,
      defaultDownloadPath: defaultDownloadPath ?? this.defaultDownloadPath,
      downloadSchema: downloadSchema ?? this.downloadSchema,
      errorMessage: errorMessage,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      languageCode: languageCode ?? this.languageCode,
      showReadNowButton: showReadNowButton ?? this.showReadNowButton,
      showSendToEReaderButton:
          showSendToEReaderButton ?? this.showSendToEReaderButton,
      storeReadNowAndSendToEReaderOnDevice:
          storeReadNowAndSendToEReaderOnDevice ??
          this.storeReadNowAndSendToEReaderOnDevice,
      isWebDavSyncEnabled: isWebDavSyncEnabled ?? this.isWebDavSyncEnabled,
      webDavUrl: webDavUrl ?? this.webDavUrl,
      webDavUsername: webDavUsername ?? this.webDavUsername,
      webDavPassword: webDavPassword ?? this.webDavPassword,
      epubScrollDirection: epubScrollDirection ?? this.epubScrollDirection,
      isEInkMode: isEInkMode ?? this.isEInkMode,
      bookActionsOrder: bookActionsOrder ?? this.bookActionsOrder,
      enabledBookActions: enabledBookActions ?? this.enabledBookActions,
      bookDetailsSectionsOrder:
          bookDetailsSectionsOrder ?? this.bookDetailsSectionsOrder,
      enabledBookDetailsSections:
          enabledBookDetailsSections ?? this.enabledBookDetailsSections,
      discoverMainSectionsOrder:
          discoverMainSectionsOrder ?? this.discoverMainSectionsOrder,
      enabledDiscoverMainSections:
          enabledDiscoverMainSections ?? this.enabledDiscoverMainSections,
      discoverItemsOrder: discoverItemsOrder ?? this.discoverItemsOrder,
      enabledDiscoverItems: enabledDiscoverItems ?? this.enabledDiscoverItems,
      categoryItemsOrder: categoryItemsOrder ?? this.categoryItemsOrder,
      enabledCategoryItems: enabledCategoryItems ?? this.enabledCategoryItems,
      downloaderTestStatus: downloaderTestStatus ?? this.downloaderTestStatus,
      webDavTestStatus: webDavTestStatus ?? this.webDavTestStatus,
      testErrorMessage: testErrorMessage,
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
    downloaderUsername,
    downloaderPassword,
    isSend2ereaderEnabled,
    send2ereaderUrl,
    defaultDownloadPath,
    downloadSchema,
    errorMessage,
    appVersion,
    buildNumber,
    languageCode,
    showReadNowButton,
    showSendToEReaderButton,
    storeReadNowAndSendToEReaderOnDevice,
    isWebDavSyncEnabled,
    webDavUrl,
    webDavUsername,
    webDavPassword,
    epubScrollDirection,
    isEInkMode,
    bookActionsOrder,
    enabledBookActions,
    bookDetailsSectionsOrder,
    enabledBookDetailsSections,
    discoverMainSectionsOrder,
    enabledDiscoverMainSections,
    discoverItemsOrder,
    enabledDiscoverItems,
    categoryItemsOrder,
    enabledCategoryItems,
    downloaderTestStatus,
    webDavTestStatus,
    testErrorMessage,
  ];
}
