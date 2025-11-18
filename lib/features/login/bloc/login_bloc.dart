import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository loginRepository;
  final Logger logger;

  LoginBloc({required this.loginRepository, required this.logger})
    : super(const LoginState()) {
    on<EnterUrl>(_onEnterUrl);
    on<EnterUsername>(_onEnterUsername);
    on<EnterPassword>(_onEnterPassword);
    on<SubmitLogin>(_onSubmitLogin);
    on<LoadStoredCredentials>(_onLoadStoredCredentials);
  }

  void _onEnterUrl(EnterUrl event, Emitter<LoginState> emit) {
    emit(state.copyWith(url: event.url));
  }

  void _onEnterUsername(EnterUsername event, Emitter<LoginState> emit) {
    emit(state.copyWith(username: event.username));
  }

  void _onEnterPassword(EnterPassword event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onSubmitLogin(
    SubmitLogin event,
    Emitter<LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isFailure: false,
        isSuccess: false,
        errorMessage: null,
      ),
    );

    try {
      final success = await loginRepository.login(
        state.username,
        state.password,
        state.url,
      );

      if (success) {
        logger.i('Login successful');
        emit(
          state.copyWith(isLoading: false, isSuccess: true, isFailure: false),
        );
      } else {
        logger.w('Login failed');

        emit(
          state.copyWith(
            isLoading: false,
            isSuccess: false,
            isFailure: true,
            errorMessage: 'Invalid username or password',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          isFailure: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadStoredCredentials(
    LoadStoredCredentials event,
    Emitter<LoginState> emit,
  ) async {
    try {
      final credentials = await loginRepository.getStoredCredentials();
      if (credentials != null) {
        emit(
          state.copyWith(
            url: credentials.baseUrl,
            username: credentials.username,
            password: credentials.password,
          ),
        );
        logger.i('Stored credentials loaded successfully');
      }
    } catch (e) {
      logger.e('Error loading stored credentials: $e');
    }
  }
}
