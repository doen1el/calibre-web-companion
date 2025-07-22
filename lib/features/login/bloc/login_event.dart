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
