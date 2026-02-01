import 'package:equatable/equatable.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';

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
  final List<LoginCredentials> savedAccounts;

  const LoginState({
    this.url = '',
    this.username = '',
    this.password = '',
    this.redirectUrl,
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.loadingType = LoginLoadingType.standard,
    this.serverType = ServerType.calibreWeb,
    this.savedAccounts = const [],
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
    List<LoginCredentials>? savedAccounts,
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
      savedAccounts: savedAccounts ?? this.savedAccounts,
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
    savedAccounts,
  ];
}
