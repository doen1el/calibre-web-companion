import 'dart:convert';

import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageProgress {
  final int page;
  final int pageCount;
  final int timestamp;

  const PageProgress({
    required this.page,
    required this.pageCount,
    required this.timestamp,
  });

  double get percentage =>
      pageCount <= 1 ? 100 : (page / (pageCount - 1) * 100).clamp(0, 100);

  String toJson() =>
      jsonEncode({'page': page, 'pageCount': pageCount, 'ts': timestamp});

  static PageProgress? fromJson(String? raw, {int? timestamp}) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final page = decoded['page'];
      if (page is! int) return null;
      return PageProgress(
        page: page,
        pageCount: (decoded['pageCount'] as int?) ?? 0,
        timestamp: timestamp ?? (decoded['ts'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

// Page position for the PDF and comic readers. Stored per format, because a
// PDF and a CBZ of the same book do not share page numbers; WebDAV gets the
// same split so it never collides with the EPUB entry under the bare uuid.
class PageProgressStore {
  final SharedPreferences prefs;
  final Logger logger;

  PageProgressStore({required this.prefs, required this.logger});

  String _key(String uuid, String format) =>
      'page_reader_${uuid}_${format.toLowerCase()}';

  String _webDavKey(String uuid, String format) =>
      '$uuid@${format.toLowerCase()}';

  PageProgress? local(String uuid, String format) =>
      PageProgress.fromJson(prefs.getString(_key(uuid, format)));

  Future<PageProgress?> load(String uuid, String format) async {
    final localProgress = local(uuid, format);
    final webDav = await _webDav();
    if (webDav == null) return localProgress;

    try {
      final entry = (await webDav.fetchProgress())[_webDavKey(uuid, format)];
      if (entry is! Map) return localProgress;
      final remote = PageProgress.fromJson(
        entry['locator'] as String?,
        timestamp: entry['timestamp'] as int?,
      );
      if (remote == null) return localProgress;
      if (localProgress == null || remote.timestamp > localProgress.timestamp) {
        await prefs.setString(_key(uuid, format), remote.toJson());
        return remote;
      }
    } catch (e) {
      logger.w('Could not fetch page progress from WebDAV: $e');
    }
    return localProgress;
  }

  Future<void> saveLocal(String uuid, String format, PageProgress progress) =>
      prefs.setString(_key(uuid, format), progress.toJson());

  Future<void> push(String uuid, String format) async {
    final progress = local(uuid, format);
    if (progress == null) return;
    final webDav = await _webDav();
    if (webDav == null) return;
    try {
      await webDav.saveProgress(
        _webDavKey(uuid, format),
        progress.toJson(),
        progress.timestamp,
      );
    } catch (e) {
      logger.w('Could not push page progress to WebDAV: $e');
    }
  }

  Future<WebDavSyncService?> _webDav() async {
    if (!(prefs.getBool('webdav_enabled') ?? false)) return null;
    final url = prefs.getString('webdav_url') ?? '';
    if (url.isEmpty) return null;
    return WebDavSyncService(logger: logger)..init(
      url,
      prefs.getString('webdav_username') ?? '',
      prefs.getString('webdav_password') ?? '',
      allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
    );
  }
}
