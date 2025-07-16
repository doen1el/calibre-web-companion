class LoginCredentials {
  final String username;
  final String password;
  final String baseUrl;

  LoginCredentials({
    required this.username,
    required this.password,
    required this.baseUrl,
  });

  Map<String, String> toFormData() {
    return {'username': username, 'password': password};
  }
}
