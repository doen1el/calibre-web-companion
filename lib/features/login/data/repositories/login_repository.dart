import 'package:calibre_web_companion/core/exceptions/auth_exception.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';

class LoginRepository {
  final LoginRemoteDataSource dataSource;
  final Logger logger;

  LoginRepository({required this.dataSource, required this.logger});

  Future<bool> login(String username, String password, String baseUrl) async {
    try {
      final credentials = LoginCredentials(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );

      return await dataSource.login(credentials);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    return dataSource.canAccessWebsite();
  }
}
