import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthSystem {
  none,
  authelia,
  cloudflareZeroTrust,
  swag,
  traefik,
  nginxProxy,
  custom,
}

class LoginSettingsViewModel extends ChangeNotifier {
  Logger logger = Logger();

  List<Map<String, String>> _customHeaders = [];
  bool _isLoading = true;
  String _basePath = '';
  AuthSystem _selectedAuthSystem = AuthSystem.none;

  // Getter
  List<Map<String, String>> get customHeaders => _customHeaders;
  bool get isLoading => _isLoading;
  String get basePath => _basePath;
  AuthSystem get selectedAuthSystem => _selectedAuthSystem;

  Map<AuthSystem, String> get authSystemNames => {
    AuthSystem.none: 'None',
    AuthSystem.authelia: 'Authelia',
    AuthSystem.cloudflareZeroTrust: 'Cloudflare Zero Trust',
    AuthSystem.swag: 'SWAG',
    AuthSystem.traefik: 'Traefik',
    AuthSystem.nginxProxy: 'Nginx Proxy Manager',
    AuthSystem.custom: 'Custom',
  };

  /// Get string from SharedPreferences
  Future<String> getString(String string) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(string) ?? '[]';
  }

  /// Set string in SharedPreferences
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Load all settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadHeaders();

      final prefs = await SharedPreferences.getInstance();
      _basePath = prefs.getString('base_path') ?? '';

      final authSystemString = prefs.getString('auth_system') ?? 'none';
      try {
        _selectedAuthSystem = AuthSystem.values.firstWhere(
          (e) => e.toString().split('.').last == authSystemString,
          orElse: () => AuthSystem.none,
        );
      } catch (e) {
        _selectedAuthSystem = AuthSystem.none;
      }

      logger.i('Loaded auth system: $_selectedAuthSystem');
      logger.i('Loaded base path: $_basePath');
    } catch (e) {
      logger.e('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load headers from SharedPreferences
  Future<void> loadHeaders() async {
    try {
      final headersJson = await getString('custom_login_headers');

      final List<dynamic> decodedList = jsonDecode(headersJson);
      _customHeaders =
          decodedList
              .map((item) => Map<String, String>.from(item as Map))
              .toList();
      logger.i('Loaded headers: $_customHeaders');
    } catch (e) {
      _customHeaders = [];
      logger.e('Error loading headers: $e');
    }
  }

  /// Save all settings to SharedPreferences
  Future<void> saveAllSettings() async {
    try {
      await _saveHeaders();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_path', _basePath);
      await prefs.setString(
        'auth_system',
        _selectedAuthSystem.toString().split('.').last,
      );

      logger.i('Saved all settings');
    } catch (e) {
      logger.e('Error saving settings: $e');
    }
  }

  /// Save headers to SharedPreferences
  Future<void> _saveHeaders() async {
    try {
      final headersJson = jsonEncode(_customHeaders);
      await setString("custom_login_headers", headersJson);

      logger.i('Saved headers: $_customHeaders');
    } catch (e) {
      logger.e('Error saving headers: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Update base path
  void setBasePath(String newBasePath) {
    if (newBasePath.isNotEmpty) {
      if (newBasePath.startsWith('/')) {
        newBasePath = newBasePath.substring(1);
      }
      if (newBasePath.endsWith('/')) {
        newBasePath = newBasePath.substring(0, newBasePath.length - 1);
      }
    }

    _basePath = newBasePath;
    notifyListeners();
  }

  /// Set authentication system and apply predefined headers
  void setAuthSystem(AuthSystem system) {
    _selectedAuthSystem = system;

    switch (system) {
      case AuthSystem.none:
        _customHeaders = [];
        break;

      case AuthSystem.authelia:
        _customHeaders = [
          {'Remote-User': '\${USERNAME}'},
          {'Remote-Name': '\${USERNAME}'},
          {'Remote-Email': '\${USERNAME}@example.com'},
          {'Remote-Groups': 'calibre_users'},
        ];
        break;

      case AuthSystem.cloudflareZeroTrust:
        _customHeaders = [
          {'CF-Access-Client-Id': ''},
          {'CF-Access-Client-Secret': ''},
          {'CF-Access-Jwt-Assertion': ''},
        ];
        break;

      case AuthSystem.swag:
        _customHeaders = [
          {'X-Forwarded-Host': 'true'},
          {'X-Forwarded-Proto': 'https'},
          {'X-Forwarded-For': ''},
        ];
        break;

      case AuthSystem.traefik:
        _customHeaders = [
          {'X-Forwarded-User': '\${USERNAME}'},
          {'X-Forwarded-Proto': 'https'},
          {'X-Forwarded-Method': 'GET'},
        ];
        break;

      case AuthSystem.nginxProxy:
        _customHeaders = [
          {'X-Forwarded-User': '\${USERNAME}'},
          {'X-Forwarded-Proto': 'https'},
          {'X-Real-IP': ''},
        ];
        break;

      case AuthSystem.custom:
        if (_customHeaders.isEmpty) {
          _customHeaders = [
            {'': ''},
          ];
        }
        break;
    }

    _saveHeaders();
  }

  /// Add new header
  void addHeader() {
    _customHeaders.add({'': ''});
    _saveHeaders();
  }

  /// Delete header
  void deleteHeader(int index) {
    _customHeaders.removeAt(index);
    _saveHeaders();
  }

  /// Update header key
  ///
  /// Parameters:
  ///
  /// - `index`: Index of the header to update
  /// - `newKey`: New key to set
  void updateHeaderKey(int index, String newKey) {
    final value = _customHeaders[index].values.first;
    _customHeaders[index] = {newKey: value};
    _saveHeaders();
  }

  /// Update header value
  ///
  /// Parameters:
  ///
  /// - `index`: Index of the header to update
  /// - `newValue`: New value to set
  void updateHeaderValue(int index, String newValue) {
    final key = _customHeaders[index].keys.first;
    _customHeaders[index] = {key: newValue};
    _saveHeaders();
  }
}
