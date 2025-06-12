import 'package:calibre_web_companion/core/exceptions/auth_exception.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/services/api_service.dart';
import '../models/login_credentials.dart';

class LoginDataSource {
  final ApiService _apiService;
  final Logger _logger = Logger();

  LoginDataSource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Attempts to login with the given credentials
  Future<bool> login(LoginCredentials credentials) async {
    try {
      // Save base URL to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', credentials.baseUrl);
      await prefs.setString('username', credentials.username);
      await prefs.setString('password', credentials.password);

      // Initialize API with new values
      await _apiService.initialize();

      // Perform login request
      final response = await _apiService.post(
        '/login',
        null,
        credentials.toFormData(),
        AuthMethod.none,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final isSuccess = !response.body.contains('flash_danger');

        if (isSuccess) {
          if (response.headers.containsKey('set-cookie')) {
            final cookie = response.headers['set-cookie']!;
            await prefs.setString('calibre_web_session', cookie);
            await _apiService.initialize();
            _logger.i('Session cookie saved');
          } else {
            _logger.w('No cookie received in login response');
          }
          _logger.i('Login successful');
          return true;
        } else {
          _logger.w('Login failed - invalid credentials');
          throw AuthException('Invalid username or password');
        }
      }

      _logger.e(
        'Login failed: ${response.reasonPhrase ?? response.body} ${response.statusCode}',
      );
      throw AuthException(
        response.reasonPhrase ?? response.body,
        statusCode: response.statusCode,
      );
    } catch (e) {
      _logger.e("Error during login: $e");
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Connection error: ${e.toString().split(': ').last}');
    }
  }

  /// Checks if there are stored credentials and if they are valid by making a test request
  Future<bool> hasStoredCredentials() async {
    /// TODO: BEtter idea: Check / and look for the test "login"
    _logger.i('Checking stored credentials...');
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (baseUrl == null || username == null || password == null) {
      return false;
    }

    try {
      // Re-initialize API with stored credentials
      await _apiService.initialize();

      // Attempt a simple authenticated request (e.g., to /opds or /admin)
      final response = await _apiService.get('/opds', AuthMethod.basic);

      _logger.i(response.body);

      // Consider 200 as valid credentials
      return response.statusCode == 200;
    } catch (e) {
      _logger.w('Credential validation failed: $e');
      return false;
    }
  }

  /// Clears stored credentials
  Future<void> clearCredentials() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('base_url');
    // await prefs.remove('username');
    // await prefs.remove('password');
    // await prefs.remove('calibre_web_session');
  }
}
