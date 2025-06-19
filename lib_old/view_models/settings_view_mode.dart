import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSource { system, custom }

enum DownloadSchema {
  flat, // Just the book file in the selected directory
  authorOnly, // author/book.epub
  authorBook, // author/book/book.epub
  authorSeriesBook, // author/series/book/book.epub
}

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
  bool _isCostumSend2ereaderEnabled = false;
  String _downloaderUrl = '';
  String _send2ereaderUrl = '';
  final TextEditingController downloaderUrlController = TextEditingController();
  final TextEditingController send2ereaderUrlController =
      TextEditingController();
  String? _appVersion;
  String? _buildNumber;
  String? _defaultDownloadPath;
  String? _baseUrl;
  DownloadSchema _downloadSchema = DownloadSchema.flat;

  // Getters
  ThemeMode get currentTheme => _currentTheme;
  ThemeSource get themeSource => _themeSource;
  MaterialColor get selectedColor => _selectedColor;
  String get selectedColorKey => _selectedColorKey;
  bool get isDownloaderEnabled => _isDownloaderEnabled;
  String get downloaderUrl => _downloaderUrl;
  String get appVersion => _appVersion ?? '';
  String get buildNumber => _buildNumber ?? '';
  String get defaultDownloadPath => _defaultDownloadPath ?? '';
  DownloadSchema get downloadSchema => _downloadSchema;
  String get baseUrl => _baseUrl ?? '';
  String get send2ereaderUrl => _send2ereaderUrl;
  bool get isCostumSend2ereaderEnabled => _isCostumSend2ereaderEnabled;

  Future<void> loadSettings() async {
    await loadCurrentTheme();
    await loadThemeSourceAndColor();
    await loadDownloaderSettings();
    await loadSend2ereaderSettings();
    await loadDefaultDownloadInfo();
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

  /// Load the default download path and schema from SharedPreferences
  Future<void> loadDefaultDownloadInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultDownloadPath = prefs.getString('default_download_path') ?? '';
      final schemaIndex =
          prefs.getInt('download_schema') ?? DownloadSchema.flat.index;
      _downloadSchema = DownloadSchema.values[schemaIndex];

      _baseUrl = prefs.getString('base_path');

      logger.i('Loaded default download path: $_defaultDownloadPath');
      notifyListeners();
    } catch (e) {
      logger.e('Error loading default download path: $e');
    }
  }

  /// Set the default download path
  ///
  /// Parameters:
  ///
  /// - `path`: The new default download path
  Future<void> setDefaultDownloadPath(String path) async {
    _defaultDownloadPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_download_path', path);
    notifyListeners();
  }

  /// Set the download schema
  /// Parameters:
  ///
  /// - `schema`: The new download schema
  Future<void> setDownloadSchema(DownloadSchema schema) async {
    _downloadSchema = schema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('download_schema', schema.index);
    notifyListeners();
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

  /// Load send2ereader settings from SharedPreferences
  Future<void> loadSend2ereaderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isCostumSend2ereaderEnabled =
          prefs.getBool('send2ereader_enabled') ?? false;
      _send2ereaderUrl =
          prefs.getString('send2ereader_url') ?? 'https://send.djazz.se';
      send2ereaderUrlController.text = _send2ereaderUrl;

      notifyListeners();
    } catch (e) {
      logger.e('Error loading send2ereader settings: $e');
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

  /// Toggle send2ereader enabled state
  ///
  /// Parameters:
  ///
  /// - `value`: The new value
  Future<void> toggleSend2ereader(bool value) async {
    _isCostumSend2ereaderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('send2ereader_enabled', value);
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

  /// Set send2ereader URL
  ///
  /// Parameters:
  ///
  /// - `url`: The new URL
  Future<void> setSend2ereaderUrl(String url) async {
    _send2ereaderUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('send2ereader_url', url);
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
