import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginSettingsViewModel extends ChangeNotifier {
  Logger logger = Logger();

  List<Map<String, String>> _customHeaders = [];
  bool _isLoading = true;

  List<Map<String, String>> get customHeaders => _customHeaders;
  bool get isLoading => _isLoading;

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

  /// Load headers from SharedPreferences
  Future<void> loadHeaders() async {
    _isLoading = true;
    notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
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
