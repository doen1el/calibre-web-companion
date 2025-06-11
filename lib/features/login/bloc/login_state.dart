import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final String url;
  final String username;
  final String password;
  final bool isLoading;
  final bool isSuccess;
  final bool isFailure;
  final String? errorMessage;

  const LoginState({
    this.url = '',
    this.username = '',
    this.password = '',
    this.isLoading = false,
    this.isSuccess = false,
    this.isFailure = false,
    this.errorMessage,
  });

  LoginState copyWith({
    String? url,
    String? username,
    String? password,
    bool? isLoading,
    bool? isSuccess,
    bool? isFailure,
    String? errorMessage,
  }) {
    return LoginState(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isFailure: isFailure ?? this.isFailure,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    url,
    username,
    password,
    isLoading,
    isSuccess,
    isFailure,
    errorMessage,
  ];
}
