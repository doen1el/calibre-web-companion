import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class SetThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const SetThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class SetThemeSource extends SettingsEvent {
  final ThemeSource themeSource;

  const SetThemeSource(this.themeSource);

  @override
  List<Object?> get props => [themeSource];
}

class SetSelectedColor extends SettingsEvent {
  final String colorKey;

  const SetSelectedColor(this.colorKey);

  @override
  List<Object?> get props => [colorKey];
}

class SetDownloadFolder extends SettingsEvent {
  final String downloadFolder;

  const SetDownloadFolder(this.downloadFolder);

  @override
  List<Object?> get props => [downloadFolder];
}

class SetDownloadSchema extends SettingsEvent {
  final DownloadSchema downloadSchema;

  const SetDownloadSchema(this.downloadSchema);

  @override
  List<Object?> get props => [downloadSchema];
}

class SetCostumSend2EreaderEnabled extends SettingsEvent {
  final bool enabled;

  const SetCostumSend2EreaderEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetCostumSend2EreaderUrl extends SettingsEvent {
  final String url;

  const SetCostumSend2EreaderUrl(this.url);

  @override
  List<Object?> get props => [url];
}

class SetDownloaderEnabled extends SettingsEvent {
  final bool enabled;

  const SetDownloaderEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetDownloaderUrl extends SettingsEvent {
  final String url;

  const SetDownloaderUrl(this.url);

  @override
  List<Object?> get props => [url];
}

class SetDownloaderCredentials extends SettingsEvent {
  final String username;
  final String password;

  const SetDownloaderCredentials(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class SubmitFeedback extends SettingsEvent {
  final String? title;
  final String? description;

  const SubmitFeedback(this.title, this.description);

  @override
  List<Object?> get props => [];
}

class SetLanguage extends SettingsEvent {
  final String languageCode;

  const SetLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class SetShowReadNowButton extends SettingsEvent {
  final bool enabled;

  const SetShowReadNowButton(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class BuyMeACoffee extends SettingsEvent {
  const BuyMeACoffee();

  @override
  List<Object?> get props => [];
}

class SetWebDavSyncEnabled extends SettingsEvent {
  final bool enabled;
  const SetWebDavSyncEnabled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SetWebDavUrl extends SettingsEvent {
  final String url;
  const SetWebDavUrl(this.url);
  @override
  List<Object?> get props => [url];
}

class SetWebDavCredentials extends SettingsEvent {
  final String username;
  final String password;
  const SetWebDavCredentials(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class TestDownloaderConnection extends SettingsEvent {
  final String url;
  final String username;
  final String password;

  const TestDownloaderConnection({
    required this.url,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [url, username, password];
}

class TestWebDavConnection extends SettingsEvent {
  final String url;
  final String username;
  final String password;

  const TestWebDavConnection({
    required this.url,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [url, username, password];
}

class SetEpubScrollDirection extends SettingsEvent {
  final String direction;

  const SetEpubScrollDirection(this.direction);

  @override
  List<Object?> get props => [direction];
}

class ResetConnectionTestStatus extends SettingsEvent {}

class SetShowSendToEReaderButton extends SettingsEvent {
  final bool enabled;

  const SetShowSendToEReaderButton(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
