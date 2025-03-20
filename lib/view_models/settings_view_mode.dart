import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSource { system, custom }

AdaptiveThemeMode? _lastSavedThemeMode;

class SettingsViewModel extends ChangeNotifier {
  var logger = Logger();

  final GlobalKey<NavigatorState> navigatorKey;
  final String initialColorKey;
  final ThemeSource initialThemeSource;

  SettingsViewModel({
    required this.navigatorKey,
    this.initialColorKey = 'lightGreen',
    this.initialThemeSource = ThemeSource.custom,
  }) {
    _selectedColorKey = initialColorKey;
    _selectedColor = predefinedColors[initialColorKey] ?? Colors.lightGreen;
    _themeSource = initialThemeSource;
  }
  // Properties
  ThemeMode _currentTheme = ThemeMode.system;
  ThemeSource _themeSource = ThemeSource.custom;

  MaterialColor _selectedColor = Colors.lightGreen;
  String _selectedColorKey = 'lightGreen';

  // Define predefined colors as a static Map for easier access in the view
  static final Map<String, MaterialColor> predefinedColors = {
    'lightGreen': Colors.lightGreen,
    'amber': Colors.amber,
    'blueGrey': Colors.blueGrey,
    'grey': Colors.grey,
    'lightBlue': Colors.lightBlue,
    'lime': Colors.lime,
    'teal': Colors.teal,
  };

  final Map<String, String> predefinedColorNames = {
    'lightGreen': 'Light Green',
    'amber': 'Amber',
    'blueGrey': 'Blue Grey',
    'grey': 'Grey',
    'lightBlue': 'Light Blue',
    'lime': 'Lime',
    'teal': 'Teal',
  };

  bool _isDownloaderEnabled = false;
  String _downloaderUrl = '';
  final TextEditingController downloaderUrlController = TextEditingController();
  String? _appVersion;
  String? _buildNumber;

  // Getters
  ThemeMode get currentTheme => _currentTheme;
  ThemeSource get themeSource => _themeSource;
  MaterialColor get selectedColor => _selectedColor;
  String get selectedColorKey => _selectedColorKey;
  bool get isDownloaderEnabled => _isDownloaderEnabled;
  String get downloaderUrl => _downloaderUrl;
  String get appVersion => _appVersion ?? '';
  String get buildNumber => _buildNumber ?? '';

  Future<void> loadSettings() async {
    await loadCurrentTheme();
    await loadThemeSourceAndColor();
    await loadDownloaderSettings();
    await loadAppInfo();
  }

  /// Load the theme source and selected color from SharedPreferences
  Future<void> loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      logger.i(
        'Loaded app info: ${packageInfo.appName} ${packageInfo.version}+${packageInfo.buildNumber}',
      );
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      notifyListeners();
    } catch (e) {
      _appVersion = 'Unknown';
      logger.e('Error loading app info: $e');
      notifyListeners();
    }
  }

  /// Loads the theme source and color from SharedPreferences
  Future<void> loadThemeSourceAndColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourceIndex =
          prefs.getInt('theme_source') ?? initialThemeSource.index;
      _themeSource = ThemeSource.values[sourceIndex];

      _selectedColorKey = prefs.getString('theme_color_key') ?? initialColorKey;
      _selectedColor = predefinedColors[_selectedColorKey] ?? Colors.lightGreen;

      logger.i('Loaded theme source: $_themeSource, color: $_selectedColor');
      notifyListeners();
    } catch (e) {
      logger.e('Error loading theme source and color: $e');
    }
  }

  /// Set the selected color
  ///
  /// Parameters:
  ///
  /// - `source`: The new theme source
  Future<void> setThemeSource(ThemeSource source) async {
    if (_themeSource == source) return;

    _themeSource = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_source', source.index);

    notifyListeners();
  }

  /// Set the selected color
  ///
  /// Parameters:
  ///
  /// - `colorKey`: The key of the selected color
  Future<void> setSelectedColor(String colorKey) async {
    if (_selectedColorKey == colorKey) return;
    if (!predefinedColors.containsKey(colorKey)) return;

    _selectedColorKey = colorKey;
    _selectedColor = predefinedColors[colorKey]!;
    _themeSource = ThemeSource.custom;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color_key', colorKey);
    await prefs.setInt('theme_source', ThemeSource.custom.index);

    notifyListeners();
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
  ///
  /// Parameters:
  ///
  /// - `value`: The new value
  Future<void> toggleDownloader(bool value) async {
    _isDownloaderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloader_enabled', value);
    notifyListeners();
  }

  /// Set downloader URL
  ///
  /// Parameters:
  ///
  /// - `url`: The new URL
  Future<void> setDownloaderUrl(String url) async {
    _downloaderUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloader_url', url);
    notifyListeners();
  }

  /// Load the current theme from the system settings
  Future<void> loadCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex =
          prefs.getInt('theme_mode') ?? ThemeMode.system.index;
      _currentTheme = ThemeMode.values[themeModeIndex];

      logger.i('Loaded theme mode: $_currentTheme');
    } catch (e) {
      logger.e('Error loading current theme: $e');
      _currentTheme = ThemeMode.system;
    }
  }

  /// Set the theme
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `themeMode`: The theme mode to set
  Future<void> setTheme(ThemeMode themeMode) async {
    if (_currentTheme == themeMode) return;

    _currentTheme = themeMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', themeMode.index);
    logger.i('Set theme mode: $themeMode');

    try {
      switch (themeMode) {
        case ThemeMode.light:
          _lastSavedThemeMode = AdaptiveThemeMode.light;
          break;
        case ThemeMode.dark:
          _lastSavedThemeMode = AdaptiveThemeMode.dark;
          break;
        case ThemeMode.system:
          _lastSavedThemeMode = AdaptiveThemeMode.system;
          break;
      }
    } catch (e) {
      logger.e('Error setting AdaptiveTheme: $e');
    }

    notifyListeners();
  }
}
