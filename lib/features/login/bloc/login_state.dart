import 'package:equatable/equatable.dart';

enum LoginStatus { initial, success, loading, failure, redirect }

enum LoginLoadingType { initial, standard, sso }

class LoginState extends Equatable {
  final String url;
  final String username;
  final String password;
  final String? redirectUrl;
  final LoginStatus status;
  final String? errorMessage;
  final LoginLoadingType loadingType;

  const LoginState({
    this.url = '',
    this.username = '',
    this.password = '',
    this.redirectUrl,
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.loadingType = LoginLoadingType.initial,
  });

  LoginState copyWith({
    String? url,
    String? username,
    String? password,
    String? redirectUrl,
    LoginStatus? status,
    String? errorMessage,
    LoginLoadingType? loadingType,
  }) {
    return LoginState(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      status: status ?? this.status,
      errorMessage: errorMessage,
      loadingType: loadingType ?? this.loadingType,
    );
  }

  @override
  List<Object?> get props => [
    url,
    username,
    password,
    redirectUrl,
    status,
    errorMessage,
    loadingType,
  ];
}
