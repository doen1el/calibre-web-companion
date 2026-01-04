import 'package:calibre_web_companion/features/login/bloc/login_state.dart';
import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class EnterUrl extends LoginEvent {
  final String url;

  const EnterUrl(this.url);

  @override
  List<Object?> get props => [url];
}

class EnterUsername extends LoginEvent {
  final String username;

  const EnterUsername(this.username);

  @override
  List<Object?> get props => [username];
}

class EnterPassword extends LoginEvent {
  final String password;

  const EnterPassword(this.password);

  @override
  List<Object?> get props => [password];
}

class SubmitLogin extends LoginEvent {
  const SubmitLogin();
}

class SubmitSsoLogin extends LoginEvent {
  const SubmitSsoLogin();
}

class ResetLoginStatus extends LoginEvent {
  const ResetLoginStatus();
}

class LoginLogOut extends LoginEvent {
  const LoginLogOut();
}

class LoadStoredCredentials extends LoginEvent {
  const LoadStoredCredentials();
}

class ChangeServerType extends LoginEvent {
  final ServerType serverType;
  const ChangeServerType(this.serverType);

  @override
  List<Object?> get props => [serverType];
}

class FinalizeSsoLogin extends LoginEvent {
  final String cookieHeader;
  final String userAgent;
  final String baseUrl;
  final String? username;
  final String? password;

  const FinalizeSsoLogin({
    required this.cookieHeader,
    required this.userAgent,
    required this.baseUrl,
    this.username,
    this.password,
  });

  @override
  List<Object?> get props => [
    cookieHeader,
    userAgent,
    baseUrl,
    username,
    password,
  ];
}
