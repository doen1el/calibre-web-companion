import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  Logger logger = Logger();
  bool isLoading = false;
  String errorMessage = '';

  /// Attempt to login to the Calibre-Web server
  ///
  /// Parameters:
  ///
  /// - `username`: The username to login with
  /// - `password`: The password to login with
  /// - `baseUrl`: The base URL of the Calibre-Web server
  Future<bool> login(String username, String password, String baseUrl) async {
    isLoading = true;
    notifyListeners();

    try {
      // Save base URL, username and password to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', baseUrl);
      await prefs.setString('username', username);
      await prefs.setString('password', password);

      final apiService = ApiService();
      await apiService.initialize(); // Reinitialize with new values

      final response = await apiService.post(
        '/login',
        null,
        {'username': username, 'password': password, 'remember_me': 'on'},
        AuthMethod.none,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Extract and save the session cookie

        if (response.headers.containsKey('set-cookie')) {
          final cookie = response.headers['set-cookie']!;
          await prefs.setString('calibre_web_session', cookie);
          await apiService.initialize();
          logger.i('Session cookie saved');
        } else {
          logger.w('No cookie received in login response');
        }

        // Check if login was successful
        final isSuccess =
            !response.body.contains('login-form') ||
            response.headers['location']?.contains('index') == true;

        if (isSuccess) {
          logger.i('Login successful');
          errorMessage = '';
        } else {
          logger.w('Login failed - invalid credentials');
          errorMessage = 'Invalid username or password';
        }

        return isSuccess;
      }

      logger.e('Login failed: ${response.statusCode}');
      errorMessage = 'Login failed (Error ${response.statusCode})';
      return false;
    } catch (e) {
      logger.e("Error during login: $e");
      errorMessage = 'Connection error: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
