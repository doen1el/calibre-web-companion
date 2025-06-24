import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';

class LoginRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  LoginRemoteDataSource({required this.apiService, required this.logger});

  Future<bool> login(LoginCredentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', credentials.baseUrl);
      await prefs.setString('username', credentials.username);
      await prefs.setString('password', credentials.password);

      await apiService.initialize();

      final response = await apiService.post(
        endpoint: '/login',
        body: credentials.toFormData(),
        authMethod: AuthMethod.none,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );

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
    } catch (e) {
      logger.e("Error during login: $e");
      throw Exception('Connection error: ${e.toString().split(': ').last}');
    }
  }

  Future<bool> canAccessWebsite() async {
    logger.i('Checking if user can access website...');
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (baseUrl == null || username == null || password == null) {
      return false;
    }

    try {
      await apiService.initialize();

      final response = await apiService.get(
        endpoint: '/',
        authMethod: AuthMethod.cookie,
      );

      return !response.body.contains('Login');
    } catch (e) {
      logger.e('Credential validation failed: $e');
      return false;
    }
  }
}
