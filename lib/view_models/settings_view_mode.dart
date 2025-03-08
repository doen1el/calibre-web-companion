import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class SettingsViewModel extends ChangeNotifier {
  var logger = Logger();

  // Properties
  ThemeMode _currentTheme = ThemeMode.system;

  // Getters
  ThemeMode get currentTheme => _currentTheme;

  /// Load the current theme from the system settings
  Future<void> loadCurrentTheme() async {
    try {
      final mode = await AdaptiveTheme.getThemeMode();

      switch (mode) {
        case AdaptiveThemeMode.light:
          _currentTheme = ThemeMode.light;
          break;
        case AdaptiveThemeMode.dark:
          _currentTheme = ThemeMode.dark;
          break;
        case AdaptiveThemeMode.system:
          _currentTheme = ThemeMode.system;
          break;
        default:
          _currentTheme = ThemeMode.system;
          break;
      }
    } catch (e) {
      logger.e('Error loading current theme, $e');
    }
  }

  /// Set the theme
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `themeMode`: The theme mode to set
  void setTheme(BuildContext context, ThemeMode themeMode) {
    if (_currentTheme == themeMode) return;

    _currentTheme = themeMode;

    switch (themeMode) {
      case ThemeMode.light:
        AdaptiveTheme.of(context).setLight();
        break;
      case ThemeMode.dark:
        AdaptiveTheme.of(context).setDark();
        break;
      case ThemeMode.system:
        AdaptiveTheme.of(context).setSystem();
        break;
    }

    notifyListeners();
  }
}
