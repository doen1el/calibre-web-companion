import 'package:calibre_web_companion/core/exceptions/auth_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository _loginRepository;
  final Logger _logger = Logger();

  LoginBloc({LoginRepository? loginRepository})
    : _loginRepository = loginRepository ?? LoginRepository(),
      super(const LoginState()) {
    on<EnterUrl>(_onEnterUrl);
    on<EnterUsername>(_onEnterUsername);
    on<EnterPassword>(_onEnterPassword);
    on<SubmitLogin>(_onSubmitLogin);
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
      final success = await _loginRepository.login(
        state.username,
        state.password,
        state.url,
      );

      if (success) {
        _logger.i('Login successful');
        emit(
          state.copyWith(isLoading: false, isSuccess: true, isFailure: false),
        );
      } else {
        _logger.w('Login failed');

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
      String errorMessage =
          e is AuthException
              ? e.toString()
              : e.toString().replaceAll(RegExp(r'^Exception: '), '');
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          isFailure: true,
          errorMessage: errorMessage,
        ),
      );
    }
  }
}
