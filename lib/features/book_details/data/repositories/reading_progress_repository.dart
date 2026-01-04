import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

class ReadingProgressRepository {
  final WebDavSyncService webDavService;

  ReadingProgressRepository({required this.webDavService});

  Future<EpubLocator?> getBestLocation(String bookUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final String progressKey = 'book_progress_$bookUuid';
    final String timestampKey = 'book_timestamp_$bookUuid';

    String? locationJsonToUse;
    int localTimestamp = prefs.getInt(timestampKey) ?? 0;

    locationJsonToUse = prefs.getString(progressKey);

    final webDavEnabled = prefs.getBool('webdav_enabled') ?? false;
    if (webDavEnabled) {
      try {
        final url = prefs.getString('webdav_url') ?? '';
        final user = prefs.getString('webdav_username') ?? '';
        final pass = prefs.getString('webdav_password') ?? '';

        if (url.isNotEmpty) {
          webDavService.init(url, user, pass);
          final serverData = await webDavService.fetchProgress();

          if (serverData.containsKey(bookUuid)) {
            final bookData = serverData[bookUuid];
            final int serverTimestamp = bookData['timestamp'] ?? 0;

            if (serverTimestamp > localTimestamp) {
              locationJsonToUse = bookData['locator'];
            }
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Failed to fetch progress from WebDAV: $e');
      }
    }

    if (locationJsonToUse != null && locationJsonToUse.isNotEmpty) {
      try {
        final Map<String, dynamic> decodedMap = jsonDecode(locationJsonToUse);
        return EpubLocator.fromJson(decodedMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveProgress(String bookUuid, String locatorJson) async {
    final prefs = await SharedPreferences.getInstance();
    final String progressKey = 'book_progress_$bookUuid';
    final String timestampKey = 'book_timestamp_$bookUuid';

    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(progressKey, locatorJson);
    await prefs.setInt(timestampKey, now);

    final webDavEnabled = prefs.getBool('webdav_enabled') ?? false;
    if (webDavEnabled) {
      final url = prefs.getString('webdav_url') ?? '';
      final user = prefs.getString('webdav_username') ?? '';
      final pass = prefs.getString('webdav_password') ?? '';

      if (url.isNotEmpty) {
        webDavService.init(url, user, pass);
        await webDavService.saveProgress(bookUuid, locatorJson, now);
      }
    }
  }
}
