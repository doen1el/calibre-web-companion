import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/features/settings/data/repositories/settings_repository.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

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
    on<SetDownloaderCredentials>(_onSetDownloaderCredentials);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<SetLanguage>(_onSetLanguage);
    on<SetShowReadNowButton>(_onSetShowReadNowButton);
    on<BuyMeACoffee>(_onBuyMeACoffee);
    on<SetWebDavSyncEnabled>(_onSetWebDavSyncEnabled);
    on<SetWebDavUrl>(_onSetWebDavUrl);
    on<SetWebDavCredentials>(_onSetWebDavCredentials);
    on<TestDownloaderConnection>(_onTestDownloaderConnection);
    on<TestWebDavConnection>(_onTestWebDavConnection);
    on<SetEpubScrollDirection>(_onSetEpubScrollDirection);
    on<ResetConnectionTestStatus>(_onResetConnectionTestStatus);
    on<SetShowSendToEReaderButton>(_onSetShowSendToEReaderButton);
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
          downloaderUsername: settings.downloaderUsername,
          downloaderPassword: settings.downloaderPassword,
          isSend2ereaderEnabled: settings.isSend2ereaderEnabled,
          send2ereaderUrl: settings.send2ereaderUrl,
          defaultDownloadPath: settings.defaultDownloadPath,
          downloadSchema: settings.downloadSchema,
          showReadNowButton: settings.showReadNowButton,
          showSendToEReaderButton: settings.showSendToEReaderButton,
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          languageCode: settings.languageCode,
          webDavUrl: settings.webDavUrl,
          webDavUsername: settings.webDavUsername,
          webDavPassword: settings.webDavPassword,
          isWebDavSyncEnabled: settings.isWebDavSyncEnabled,
          epubScrollDirection: settings.epubScrollDirection,
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
      if (!event.enabled) {
        await repository.setSend2ereaderUrl('https://send.djazz.se');
        emit(state.copyWith(send2ereaderUrl: 'https://send.djazz.se'));
      }
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

  Future<void> _onSetDownloaderCredentials(
    SetDownloaderCredentials event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setDownloaderCredentials(event.username, event.password);
      emit(
        state.copyWith(
          downloaderUsername: event.username,
          downloaderPassword: event.password,
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

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(feedbackStatus: SettingsFeedbackStatus.loading));

    try {
      await repository.submitFeedback(
        event.title ?? '',
        event.description ?? '',
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

  Future<void> _onSetShowReadNowButton(
    SetShowReadNowButton event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setShowReadNowButton(event.enabled);
      emit(state.copyWith(showReadNowButton: event.enabled));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onBuyMeACoffee(
    BuyMeACoffee event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.buyMeACoffee();
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetWebDavSyncEnabled(
    SetWebDavSyncEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setWebDavSyncEnabled(event.enabled);

      emit(state.copyWith(isWebDavSyncEnabled: event.enabled));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetWebDavUrl(
    SetWebDavUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setWebDavUrl(event.url);

      emit(state.copyWith(webDavUrl: event.url));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetWebDavCredentials(
    SetWebDavCredentials event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setWebDavCredentials(event.username, event.password);

      emit(
        state.copyWith(
          webDavUsername: event.username,
          webDavPassword: event.password,
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

  Future<void> _onTestDownloaderConnection(
    TestDownloaderConnection event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(downloaderTestStatus: ConnectionTestStatus.loading));
    try {
      final success = await repository.testDownloaderConnection(
        event.url,
        event.username,
        event.password,
      );

      if (success) {
        emit(
          state.copyWith(downloaderTestStatus: ConnectionTestStatus.success),
        );
      } else {
        emit(
          state.copyWith(
            downloaderTestStatus: ConnectionTestStatus.error,
            testErrorMessage: "Login failed (Invalid credentials or URL)",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          downloaderTestStatus: ConnectionTestStatus.error,
          testErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTestWebDavConnection(
    TestWebDavConnection event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(webDavTestStatus: ConnectionTestStatus.loading));
    try {
      await repository.testWebDavConnection(
        event.url,
        event.username,
        event.password,
      );
      emit(state.copyWith(webDavTestStatus: ConnectionTestStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          webDavTestStatus: ConnectionTestStatus.error,
          testErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSetEpubScrollDirection(
    SetEpubScrollDirection event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setEpubScrollDirection(event.direction);
      emit(state.copyWith(epubScrollDirection: event.direction));
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onResetConnectionTestStatus(
    ResetConnectionTestStatus event,
    Emitter<SettingsState> emit,
  ) {
    emit(
      state.copyWith(
        downloaderTestStatus: ConnectionTestStatus.initial,
        webDavTestStatus: ConnectionTestStatus.initial,
        testErrorMessage: null,
      ),
    );
  }

  Future<void> _onSetShowSendToEReaderButton(
    SetShowSendToEReaderButton event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.setShowSendToEReaderButton(event.enabled);
      emit(state.copyWith(showSendToEReaderButton: event.enabled));
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
