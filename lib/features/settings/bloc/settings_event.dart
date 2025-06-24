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

class EnterFeedbackTitle extends SettingsEvent {
  final String title;

  const EnterFeedbackTitle(this.title);

  @override
  List<Object?> get props => [title];
}

class EnterFeedbackDescription extends SettingsEvent {
  final String description;

  const EnterFeedbackDescription(this.description);

  @override
  List<Object?> get props => [description];
}

class SubmitFeedback extends SettingsEvent {
  const SubmitFeedback();

  @override
  List<Object?> get props => [];
}

class SetLanguage extends SettingsEvent {
  final String languageCode;

  const SetLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class BuyMeACoffee extends SettingsEvent {
  const BuyMeACoffee();

  @override
  List<Object?> get props => [];
}
