import 'package:equatable/equatable.dart';

class LoginCredentials extends Equatable {
  final String username;
  final String password;
  final String baseUrl;
  final String? serverType;

  const LoginCredentials({
    required this.username,
    required this.password,
    required this.baseUrl,
    this.serverType,
  });

  Map<String, String> toFormData() {
    return {'username': username, 'password': password};
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'baseUrl': baseUrl,
      'serverType': serverType,
    };
  }

  factory LoginCredentials.fromJson(Map<String, dynamic> json) {
    return LoginCredentials(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      serverType: json['serverType'],
    );
  }

  @override
  List<Object?> get props => [username, password, baseUrl, serverType];
}
