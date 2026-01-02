import 'dart:convert';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:logger/logger.dart';

class WebDavSyncService {
  final Logger logger;
  webdav.Client? _client;

  static const String _syncFileName =
      'calibre_web_companion_reading_progress.json';

  WebDavSyncService({required this.logger});

  void init(String url, String user, String password) {
    if (url.isEmpty) return;

    _client = webdav.newClient(
      url,
      user: user,
      password: password,
      debug: false,
    );
    try {
      _client!.ping();
    } catch (e) {
      logger.e("WebDAV Init Error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchProgress() async {
    if (_client == null) return {};

    try {
      final List<int> data = await _client!.read(_syncFileName);

      if (data.isEmpty) return {};

      final String jsonString = utf8.decode(data);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      logger.i("Could not read WebDAV sync file (might not exist yet): $e");
      return {};
    }
  }

  Future<void> saveProgress(
    String bookUuid,
    String locatorJson,
    int timestamp,
  ) async {
    if (_client == null) return;

    try {
      Map<String, dynamic> currentData = await fetchProgress();

      currentData[bookUuid] = {'locator': locatorJson, 'timestamp': timestamp};

      final String jsonString = jsonEncode(currentData);
      await _client!.write(_syncFileName, utf8.encode(jsonString));
      logger.i("Progress synced to WebDAV for $bookUuid");
    } catch (e) {
      logger.e("Error saving WebDAV progress: $e");
    }
  }
}
