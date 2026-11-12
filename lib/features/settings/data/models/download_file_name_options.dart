import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// File name settings for downloads (#226), stored directly in
/// SharedPreferences like the widget settings.
class DownloadFileNameOptions {
  static const String useServerFileNameKey = 'download_use_server_file_name';
  static const String asciiFileNameKey = 'download_ascii_file_name';
  static const String _serverNamesKey = 'download_server_file_names';

  final bool useServerFileName;
  final bool asciiFileName;

  const DownloadFileNameOptions({
    this.useServerFileName = false,
    this.asciiFileName = false,
  });

  factory DownloadFileNameOptions.fromPrefs(SharedPreferences prefs) =>
      DownloadFileNameOptions(
        useServerFileName: prefs.getBool(useServerFileNameKey) ?? false,
        asciiFileName: prefs.getBool(asciiFileNameKey) ?? false,
      );

  // The server name is only known from the download response; remembering it
  // lets an existing download be reopened without a request.
  static String? rememberedServerName(
    SharedPreferences prefs,
    String bookId,
    String format,
  ) => _serverNames(prefs)['$bookId.${format.toLowerCase()}'];

  static Future<void> rememberServerName(
    SharedPreferences prefs,
    String bookId,
    String format,
    String fileName,
  ) async {
    final names = _serverNames(prefs);
    names['$bookId.${format.toLowerCase()}'] = fileName;
    await prefs.setString(_serverNamesKey, jsonEncode(names));
  }

  static Map<String, String> _serverNames(SharedPreferences prefs) {
    final raw = prefs.getString(_serverNamesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
