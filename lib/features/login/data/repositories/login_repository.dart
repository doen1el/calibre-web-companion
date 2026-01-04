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
      String redirectUrl = e.location;

      if (redirectUrl.startsWith('//')) {
        final scheme = Uri.parse(baseUrl).scheme;
        redirectUrl = '$scheme:$redirectUrl';
      } else if (redirectUrl.startsWith('/')) {
        final cleanBase =
            baseUrl.endsWith('/')
                ? baseUrl.substring(0, baseUrl.length - 1)
                : baseUrl;
        redirectUrl = '$cleanBase$redirectUrl';
      }

      return LoginResult.redirect(redirectUrl);
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
      final serverType = await getStoredServerType();

      if (credentials != null && credentials.username.isNotEmpty) {
        await dataSource.login(credentials, serverType);
        logger.i('Auto-relogin successful');
        return true;
      } else {
        logger.i(
          'No stored credentials found (SSO user?). Manual login required.',
        );
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

  Future<LoginResult> finalizeSso(
    String cookieHeader,
    String userAgent,
    String baseUrl,
    String? username,
    String? password,
  ) async {
    try {
      await dataSource.finalizeSsoSession(
        cookieHeader: cookieHeader,
        userAgent: userAgent,
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
      return LoginResult.success();
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
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
