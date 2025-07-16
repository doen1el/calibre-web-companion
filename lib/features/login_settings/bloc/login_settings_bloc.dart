import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_state.dart';

import 'package:calibre_web_companion/features/login_settings/data/models/custom_header.dart';
import 'package:calibre_web_companion/features/login_settings/data/repositories/login_settings_repository.dart';

class LoginSettingsBloc extends Bloc<LoginSettingsEvent, LoginSettingsState> {
  final Logger _logger = Logger();
  final LoginSettingsRepository loginSettingsRepository;

  LoginSettingsBloc({required this.loginSettingsRepository})
    : super(const LoginSettingsState()) {
    on<LoadLoginSettings>(_onLoadSettings);
    on<AddCustomHeader>(_onAddCustomHeader);
    on<DeleteCustomHeader>(_onDeleteCustomHeader);
    on<UpdateCustomHeaderKey>(_onUpdateCustomHeaderKey);
    on<UpdateCustomHeaderValue>(_onUpdateCustomHeaderValue);
    on<SaveLoginSettings>(_onSaveSettings);
    on<UpdateBasePath>(_onUpdateBasePath);
    on<UpdateAllowSelfSigned>(_onUpdateAllowSelfSigned);
  }

  Future<void> _onLoadSettings(
    LoadLoginSettings event,
    Emitter<LoginSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSaved: false));

    try {
      final headers = await loginSettingsRepository.getCustomHeaders();
      final basePath =
          await loginSettingsRepository.getBasePath(); // Base Path laden

      emit(
        state.copyWith(
          customHeaders: headers,
          basePath: basePath,
          isLoading: false,
        ),
      );
    } catch (e) {
      _logger.e('Error loading login settings: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load login settings: $e',
        ),
      );
    }
  }

  void _onAddCustomHeader(
    AddCustomHeader event,
    Emitter<LoginSettingsState> emit,
  ) {
    final updatedHeaders = List<CustomHeaderModel>.from(state.customHeaders)
      ..add(CustomHeaderModel(key: '', value: ''));

    emit(state.copyWith(customHeaders: updatedHeaders, isSaved: false));
  }

  void _onDeleteCustomHeader(
    DeleteCustomHeader event,
    Emitter<LoginSettingsState> emit,
  ) {
    final updatedHeaders = List<CustomHeaderModel>.from(state.customHeaders);
    if (event.index >= 0 && event.index < updatedHeaders.length) {
      updatedHeaders.removeAt(event.index);
      emit(state.copyWith(customHeaders: updatedHeaders, isSaved: false));
    }
  }

  void _onUpdateCustomHeaderKey(
    UpdateCustomHeaderKey event,
    Emitter<LoginSettingsState> emit,
  ) {
    final updatedHeaders = List<CustomHeaderModel>.from(state.customHeaders);
    if (event.index >= 0 && event.index < updatedHeaders.length) {
      final oldHeader = updatedHeaders[event.index];
      updatedHeaders[event.index] = CustomHeaderModel(
        key: event.newKey,
        value: oldHeader.value,
      );

      emit(state.copyWith(customHeaders: updatedHeaders, isSaved: false));
    }
  }

  void _onUpdateCustomHeaderValue(
    UpdateCustomHeaderValue event,
    Emitter<LoginSettingsState> emit,
  ) {
    final updatedHeaders = List<CustomHeaderModel>.from(state.customHeaders);
    if (event.index >= 0 && event.index < updatedHeaders.length) {
      final oldHeader = updatedHeaders[event.index];
      updatedHeaders[event.index] = CustomHeaderModel(
        key: oldHeader.key,
        value: event.newValue,
      );

      emit(state.copyWith(customHeaders: updatedHeaders, isSaved: false));
    }
  }

  Future<void> _onSaveSettings(
    SaveLoginSettings event,
    Emitter<LoginSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isSaved: false));

    try {
      final validHeaders =
          state.customHeaders
              .where(
                (header) =>
                    header.key.trim().isNotEmpty &&
                    header.value.trim().isNotEmpty,
              )
              .toList();

      await loginSettingsRepository.saveCustomHeaders(validHeaders);

      await loginSettingsRepository.saveBasePath(state.basePath.trim());

      await loginSettingsRepository.saveAllowSelfSigned(state.allowSelfSigned);

      emit(state.copyWith(isLoading: false, isSaved: true));
    } catch (e) {
      _logger.e('Error saving settings: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to save settings: $e',
          isSaved: false,
        ),
      );
    }
  }

  void _onUpdateBasePath(
    UpdateBasePath event,
    Emitter<LoginSettingsState> emit,
  ) {
    emit(state.copyWith(basePath: event.basePath, isSaved: false));
  }

  void _onUpdateAllowSelfSigned(
    UpdateAllowSelfSigned event,
    Emitter<LoginSettingsState> emit,
  ) {
    emit(
      state.copyWith(allowSelfSigned: event.allowSelfSigned, isSaved: false),
    );
  }
}
