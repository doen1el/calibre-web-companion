import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  var logger = Logger();

  // Properties
  ThemeMode _currentTheme = ThemeMode.system;
  bool _isDownloaderEnabled = false;
  String _downloaderUrl = '';
  final TextEditingController downloaderUrlController = TextEditingController();

  // Getters
  ThemeMode get currentTheme => _currentTheme;
  bool get isDownloaderEnabled => _isDownloaderEnabled;
  String get downloaderUrl => _downloaderUrl;

  Future<void> loadSettings() async {
    await loadCurrentTheme();
    await loadDownloaderSettings();
  }

  /// Load downloader settings from SharedPreferences
  Future<void> loadDownloaderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDownloaderEnabled = prefs.getBool('downloader_enabled') ?? false;
      _downloaderUrl = prefs.getString('downloader_url') ?? '';
      downloaderUrlController.text = _downloaderUrl;
      notifyListeners();
    } catch (e) {
      logger.e('Error loading downloader settings: $e');
    }
  }

  /// Toggle downloader enabled state
  Future<void> toggleDownloader(bool value) async {
    _isDownloaderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloader_enabled', value);
    notifyListeners();
  }

  /// Set downloader URL
  Future<void> setDownloaderUrl(String url) async {
    _downloaderUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloader_url', url);
    notifyListeners();
  }

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
