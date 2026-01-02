import 'package:equatable/equatable.dart';

enum ServerType {
  calibreWeb,
  booklore,
  opds;

  String get label {
    switch (this) {
      case ServerType.calibreWeb:
        return 'Calibre Web';
      case ServerType.booklore:
        return 'Booklore';
      case ServerType.opds:
        return 'OPDS';
    }
  }
}

enum LoginStatus { initial, loading, success, failure, redirect }

enum LoginLoadingType { initial, standard, sso }

class LoginState extends Equatable {
  final String url;
  final String username;
  final String password;
  final String? redirectUrl;
  final LoginStatus status;
  final String? errorMessage;
  final LoginLoadingType loadingType;
  final ServerType serverType;

  const LoginState({
    this.url = '',
    this.username = '',
    this.password = '',
    this.redirectUrl,
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.loadingType = LoginLoadingType.standard,
    this.serverType = ServerType.calibreWeb,
  });

  LoginState copyWith({
    String? url,
    String? username,
    String? password,
    String? redirectUrl,
    LoginStatus? status,
    String? errorMessage,
    LoginLoadingType? loadingType,
    ServerType? serverType,
  }) {
    return LoginState(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      status: status ?? this.status,
      errorMessage: errorMessage,
      loadingType: loadingType ?? this.loadingType,
      serverType: serverType ?? this.serverType,
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
    serverType,
  ];
}
