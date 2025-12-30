import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';
import 'package:calibre_web_companion/core/exceptions/redirect_exception.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

abstract class LoginFailure {}

class NetworkFailure extends LoginFailure {}

class InvalidCredentialsFailure extends LoginFailure {}

class RedirectFailure extends LoginFailure {
  final String location;
  RedirectFailure(this.location);
}

class LoginRepository {
  final LoginRemoteDataSource dataSource;
  final Logger logger;

  LoginRepository({required this.dataSource, required this.logger});

  Future<LoginResult> login(
    String username,
    String password,
    String baseUrl,
    ServerType serverType,
  ) async {
    try {
      final credentials = LoginCredentials(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );

      await dataSource.login(credentials, serverType);
      return LoginResult.success();
    } on RedirectException catch (e) {
      return LoginResult.redirect(e.location);
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
  }

  Future<bool> isLoggedIn() async {
    final isSessionValid = await dataSource.canAccessWebsite();
    if (isSessionValid) {
      return true;
    }

    logger.i('Session invalid or expired. Attempting auto-relogin...');

    try {
      final credentials = await dataSource.getStoredCredentials();

      if (credentials != null) {
        await dataSource.login(credentials, await getStoredServerType());

        logger.i('Auto-relogin successful');
        return true;
      }
    } catch (e) {
      logger.w('Auto-relogin failed: $e');
    }

    return false;
  }

  Future<LoginCredentials?> getStoredCredentials() async {
    return dataSource.getStoredCredentials();
  }

  Future<ServerType> getStoredServerType() async {
    return dataSource.getStoredServerType();
  }
}

class LoginResult {
  final bool isSuccess;
  final bool isRedirect;
  final String? redirectUrl;
  final String? errorMessage;

  LoginResult._({
    required this.isSuccess,
    required this.isRedirect,
    this.redirectUrl,
    this.errorMessage,
  });

  factory LoginResult.success() =>
      LoginResult._(isSuccess: true, isRedirect: false);

  factory LoginResult.redirect(String url) =>
      LoginResult._(isSuccess: false, isRedirect: true, redirectUrl: url);

  factory LoginResult.failure(String message) =>
      LoginResult._(isSuccess: false, isRedirect: false, errorMessage: message);
}
