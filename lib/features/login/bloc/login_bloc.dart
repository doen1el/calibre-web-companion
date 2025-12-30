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
    on<SubmitSsoLogin>(_onSubmitSsoLogin);
    on<ResetLoginStatus>(_onResetLoginStatus);
    on<LoginLogOut>(_onLogOut);
    on<ChangeServerType>(_onChangeServerType); // Neu
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

  void _onLogOut(LoginLogOut event, Emitter<LoginState> emit) {
    emit(const LoginState());
  }

  void _onChangeServerType(ChangeServerType event, Emitter<LoginState> emit) {
    emit(state.copyWith(serverType: event.serverType));
  }

  Future<void> _onSubmitLogin(
    SubmitLogin event,
    Emitter<LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LoginStatus.loading,
        loadingType: LoginLoadingType.standard,
        errorMessage: null,
      ),
    );

    try {
      final result = await loginRepository.login(
        state.username,
        state.password,
        state.url,
        state.serverType,
      );

      if (result.isSuccess) {
        logger.i('Login successful');
        emit(
          state.copyWith(
            status: LoginStatus.success,
            loadingType: LoginLoadingType.initial,
          ),
        );
      } else if (result.isRedirect) {
        logger.i('Redirect detected to: ${result.redirectUrl}');
        emit(
          state.copyWith(
            status: LoginStatus.redirect,
            redirectUrl: result.redirectUrl,
            loadingType: LoginLoadingType.initial,
          ),
        );
      } else {
        logger.w('Login failed');
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: result.errorMessage ?? 'Login failed',
            loadingType: LoginLoadingType.initial,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString(),
          loadingType: LoginLoadingType.initial,
        ),
      );
    }
  }

  Future<void> _onSubmitSsoLogin(
    SubmitSsoLogin event,
    Emitter<LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LoginStatus.loading,
        loadingType: LoginLoadingType.sso,
        errorMessage: null,
      ),
    );
    try {
      final result = await loginRepository.login(
        '',
        '',
        state.url,
        state.serverType,
      );

      if (result.isRedirect) {
        logger.i('SSO Redirect detected to: ${result.redirectUrl}');
        emit(
          state.copyWith(
            status: LoginStatus.redirect,
            redirectUrl: result.redirectUrl,
            loadingType: LoginLoadingType.initial,
          ),
        );
      } else if (result.isSuccess) {
        logger.i('SSO login successful (already logged in)');
        emit(
          state.copyWith(
            status: LoginStatus.success,
            loadingType: LoginLoadingType.initial,
          ),
        );
      } else {
        logger.w('SSO Login failed: ${result.errorMessage}');
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: result.errorMessage ?? 'SSO Login failed',
            loadingType: LoginLoadingType.initial,
          ),
        );
      }
    } catch (e) {
      logger.e('Error during SSO login submission: $e');
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString(),
          loadingType: LoginLoadingType.initial,
        ),
      );
    }
  }

  void _onResetLoginStatus(ResetLoginStatus event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        status: LoginStatus.initial,
        redirectUrl: null,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onLoadStoredCredentials(
    LoadStoredCredentials event,
    Emitter<LoginState> emit,
  ) async {
    try {
      final credentials = await loginRepository.getStoredCredentials();
      final serverType = await loginRepository.getStoredServerType();

      if (credentials != null) {
        emit(
          state.copyWith(
            url: credentials.baseUrl,
            username: credentials.username,
            password: credentials.password,
            serverType: serverType,
          ),
        );
        logger.i('Stored credentials and server type loaded successfully');
      }
    } catch (e) {
      logger.e('Error loading stored credentials: $e');
    }
  }
}
