// ignore: implementation_imports
import 'package:http/src/response.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/exceptions/redirect_exception.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

class LoginRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  LoginRemoteDataSource({required this.apiService, required this.logger});

  Future<bool> login(
    LoginCredentials credentials,
    ServerType serverType,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('base_url', credentials.baseUrl);
      await prefs.setString('username', credentials.username);
      await prefs.setString('password', credentials.password);
      await prefs.setString('server_type', serverType.name);

      if (serverType == ServerType.opds || serverType == ServerType.booklore) {
        try {
          final uri = Uri.parse(credentials.baseUrl);
          final origin = uri.origin;
          final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

          await prefs.setString('base_url', origin);
          await apiService.initialize();

          await _loginOpds(credentials, path);

          await prefs.setString('base_url', credentials.baseUrl);
          await apiService.initialize();

          return true;
        } catch (e) {
          logger.w(
            'Error parsing OPDS URL, falling back to standard method: $e',
          );
          await apiService.initialize();
          return _loginOpds(credentials, '');
        }
      } else {
        await apiService.initialize();
        return _loginCalibreWeb(credentials);
      }
    } on RedirectException {
      rethrow;
    } catch (e) {
      logger.e("Error during login: $e");
      throw Exception('Connection error: ${e.toString().split(': ').last}');
    }
  }

  Future<bool> _loginOpds(LoginCredentials credentials, String endpoint) async {
    logger.i('Attempting OPDS login to endpoint: "$endpoint"...');

    final hasCredentials =
        credentials.username.isNotEmpty || credentials.password.isNotEmpty;

    final response = await apiService.get(
      endpoint: endpoint,
      authMethod: hasCredentials ? AuthMethod.basic : AuthMethod.none,
      followRedirects: true,
    );

    if (response.statusCode == 200) {
      logger.i('OPDS Login successful');
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      logger.w('OPDS Login failed - invalid credentials or auth required');
      throw Exception('Invalid username or password');
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<bool> _loginCalibreWeb(LoginCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    if (credentials.username.isEmpty && credentials.password.isEmpty) {
      logger.i('Attempting SSO login by triggering a redirect...');
      await apiService.get(endpoint: '/', followRedirects: false);
      logger.i('User is already logged in.');
      return true;
    }

    Response response;

    if (credentials.username.isEmpty && credentials.password.isEmpty) {
      response = await apiService.post(
        endpoint: '/login',
        body: credentials.toFormData(),
        followRedirects: false,
      );
    } else {
      response = await apiService.post(
        endpoint: '/login',
        body: credentials.toFormData(),
        authMethod: AuthMethod.none,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );
    }

    if (response.statusCode == 200 || response.statusCode == 302) {
      final isSuccess = !response.body.contains('flash_danger');

      if (isSuccess) {
        if (response.headers.containsKey('set-cookie')) {
          final cookie = response.headers['set-cookie']!;
          await prefs.setString('calibre_web_session', cookie);
          await apiService.initialize();
          logger.i('Session cookie saved');
        } else {
          logger.w('No cookie received in login response');
        }
        logger.i('Login successful');
        return true;
      } else {
        logger.w('Login failed - invalid credentials');
        throw Exception('Invalid username or password');
      }
    }

    logger.e(
      'Login failed: ${response.reasonPhrase ?? response.body} ${response.statusCode}',
    );
    throw Exception(response.reasonPhrase ?? response.body);
  }

  Future<bool> canAccessWebsite() async {
    logger.i('Checking if user can access website...');
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final cookie = prefs.getString('calibre_web_session');

    if (baseUrl == null || cookie == null || cookie.isEmpty) {
      return false;
    }

    try {
      await apiService.initialize();

      final response = await apiService.get(
        endpoint: '/',
        authMethod: AuthMethod.cookie,
        followRedirects: false,
      );

      return response.statusCode == 200 && !response.body.contains('Login');
    } on RedirectException {
      logger.i('Session invalid, redirect detected.');
      return false;
    } catch (e) {
      logger.e('Credential validation failed: $e');
      return false;
    }
  }

  Future<LoginCredentials?> getStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (baseUrl != null && username != null && password != null) {
      return LoginCredentials(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
    }

    return null;
  }

  Future<ServerType> getStoredServerType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString('server_type');
    if (typeStr == ServerType.opds.name) {
      return ServerType.opds;
    } else if (typeStr == ServerType.booklore.name) {
      return ServerType.booklore;
    }
    return ServerType.calibreWeb;
  }
}
