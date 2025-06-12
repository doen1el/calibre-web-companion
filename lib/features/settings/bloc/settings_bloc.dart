import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/features/settings/data/repositories/settings_repositorie.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepositorie repository;

  SettingsBloc({required this.repository}) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SetThemeMode>(_onSetThemeMode);
    on<SetThemeSource>(_onSetThemeSource);
    on<SetSelectedColor>(_onSetSelectedColor);
    on<SetDownloadFolder>(_onSetDownloadFolder);
    on<SetDownloadSchema>(_onSetDownloadSchema);
    on<SetCostumSend2EreaderEnabled>(_onSetSend2EreaderEnabled);
    on<SetCostumSend2EreaderUrl>(_onSetSend2EreaderUrl);
    on<SetDownloaderEnabled>(_onSetDownloaderEnabled);
    on<SetDownloaderUrl>(_onSetDownloaderUrl);
    on<EnterFeedbackTitle>(_onEnterFeedbackTitle);
    on<EnterFeedbackDescription>(_onEnterFeedbackDescription);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<SetLanguage>(_onSetLanguage);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));

    try {
      final settings = await repository.getSettings();
      final packageInfo = await PackageInfo.fromPlatform();

      emit(
        state.copyWith(
          status: SettingsStatus.loaded,
          themeMode: settings.themeMode,
          themeSource: settings.themeSource,
          selectedColorKey: settings.selectedColorKey,
          isDownloaderEnabled: settings.isDownloaderEnabled,
          downloaderUrl: settings.downloaderUrl,
          isSend2ereaderEnabled: settings.isSend2ereaderEnabled,
          send2ereaderUrl: settings.send2ereaderUrl,
          defaultDownloadPath: settings.defaultDownloadPath,
          downloadSchema: settings.downloadSchema,
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          languageCode: settings.languageCode,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetThemeMode(
    SetThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setThemeMode(event.themeMode);
      emit(state.copyWith(themeMode: event.themeMode));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetThemeSource(
    SetThemeSource event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setThemeSource(event.themeSource);
      emit(state.copyWith(themeSource: event.themeSource));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetSelectedColor(
    SetSelectedColor event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setSelectedColor(event.colorKey);
      emit(state.copyWith(selectedColorKey: event.colorKey));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetDownloadFolder(
    SetDownloadFolder event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setDefaultDownloadPath(event.downloadFolder);
      emit(state.copyWith(defaultDownloadPath: event.downloadFolder));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetDownloadSchema(
    SetDownloadSchema event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setDownloadSchema(event.downloadSchema);
      emit(state.copyWith(downloadSchema: event.downloadSchema));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetSend2EreaderEnabled(
    SetCostumSend2EreaderEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setSend2ereaderEnabled(event.enabled);
      emit(state.copyWith(isSend2ereaderEnabled: event.enabled));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetSend2EreaderUrl(
    SetCostumSend2EreaderUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setSend2ereaderUrl(event.url);
      emit(state.copyWith(send2ereaderUrl: event.url));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetDownloaderEnabled(
    SetDownloaderEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setDownloaderEnabled(event.enabled);
      emit(state.copyWith(isDownloaderEnabled: event.enabled));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetDownloaderUrl(
    SetDownloaderUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setDownloaderUrl(event.url);
      emit(state.copyWith(downloaderUrl: event.url));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onEnterFeedbackTitle(
    EnterFeedbackTitle event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(feedbackTitle: event.title));
  }

  Future<void> _onEnterFeedbackDescription(
    EnterFeedbackDescription event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(feedbackDescription: event.description));
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(feedbackStatus: SettingsFeedbackStatus.loading));

    try {
      await repository.submitFeedback(
        state.feedbackTitle ?? '',
        state.feedbackDescription ?? '',
      );
      emit(state.copyWith(status: SettingsStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          feedbackStatus: SettingsFeedbackStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetLanguage(
    SetLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setLanguage(event.languageCode);
      emit(state.copyWith(languageCode: event.languageCode));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
