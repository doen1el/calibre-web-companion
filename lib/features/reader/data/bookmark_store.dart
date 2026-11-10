import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A position the reader saved on purpose. EPUB positions are a chapter plus a
// share of it, because pages move with font size; PDF and CBZ use the page.
class ReaderBookmark {
  final String id;
  final int? chapter;
  final double? chapterFraction;
  final int? page;
  final double percentage;
  final String label;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  const ReaderBookmark({
    required this.id,
    this.chapter,
    this.chapterFraction,
    this.page,
    required this.percentage,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  factory ReaderBookmark.create({
    int? chapter,
    double? chapterFraction,
    int? page,
    required double percentage,
    required String label,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ReaderBookmark(
      id: newId(),
      chapter: chapter,
      chapterFraction: chapterFraction,
      page: page,
      percentage: percentage,
      label: label,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Ids are created offline on several devices, so the time alone could clash.
  static String newId() {
    final random = Random().nextInt(1 << 32).toRadixString(36);
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$random';
  }

  ReaderBookmark asDeleted() => ReaderBookmark(
    id: id,
    chapter: chapter,
    chapterFraction: chapterFraction,
    page: page,
    percentage: percentage,
    label: label,
    createdAt: createdAt,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    deleted: true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (chapter != null) 'chapter': chapter,
    if (chapterFraction != null) 'chapterFraction': chapterFraction,
    if (page != null) 'page': page,
    'percentage': percentage,
    'label': label,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    if (deleted) 'deleted': true,
  };

  static ReaderBookmark? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final createdAt = (json['createdAt'] as num?)?.toInt() ?? 0;
    return ReaderBookmark(
      id: id,
      chapter: (json['chapter'] as num?)?.toInt(),
      chapterFraction: (json['chapterFraction'] as num?)?.toDouble(),
      page: (json['page'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      label: json['label'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? createdAt,
      deleted: json['deleted'] == true,
    );
  }
}

// Union by id; the later edit wins, and on a tie the deletion does, so a
// bookmark removed on one device is not brought back by another.
List<ReaderBookmark> mergeBookmarks(
  Iterable<ReaderBookmark> a,
  Iterable<ReaderBookmark> b, {
  int? now,
}) {
  final byId = <String, ReaderBookmark>{};
  for (final bookmark in [...a, ...b]) {
    final existing = byId[bookmark.id];
    if (existing == null ||
        bookmark.updatedAt > existing.updatedAt ||
        (bookmark.updatedAt == existing.updatedAt && bookmark.deleted)) {
      byId[bookmark.id] = bookmark;
    }
  }
  final cutoff =
      (now ?? DateTime.now().millisecondsSinceEpoch) -
      BookmarkStore.tombstoneLifetime.inMilliseconds;
  return byId.values.where((b) => !b.deleted || b.updatedAt > cutoff).toList()
    ..sort((x, y) => x.percentage.compareTo(y.percentage));
}

bool _sameBookmarks(List<ReaderBookmark> a, List<ReaderBookmark> b) =>
    jsonEncode(a.map((e) => e.toJson()).toList()) ==
    jsonEncode(b.map((e) => e.toJson()).toList());

class BookmarkStore {
  static const String webDavFileName = 'calibre_web_companion_bookmarks.json';
  static const Duration tombstoneLifetime = Duration(days: 180);

  final SharedPreferences prefs;
  final Logger logger;
  final String bookUuid;
  final String format;

  BookmarkStore({
    required this.prefs,
    required this.logger,
    required this.bookUuid,
    required String format,
  }) : format = format.toLowerCase();

  String get _key => 'reader_bookmarks_${bookUuid}_$format';
  String get _webDavKey => '$bookUuid@$format';

  List<ReaderBookmark> _all() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(ReaderBookmark.fromJson).nonNulls.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<ReaderBookmark> all) =>
      prefs.setString(_key, jsonEncode(all.map((b) => b.toJson()).toList()));

  List<ReaderBookmark> get active =>
      mergeBookmarks(_all(), const []).where((b) => !b.deleted).toList();

  Future<List<ReaderBookmark>> add(ReaderBookmark bookmark) async {
    await _save(mergeBookmarks(_all(), [bookmark]));
    unawaited(sync());
    return active;
  }

  Future<List<ReaderBookmark>> remove(String id) async {
    final all = _all();
    final target = all.where((b) => b.id == id).firstOrNull;
    if (target == null) return active;
    await _save(mergeBookmarks(all, [target.asDeleted()]));
    unawaited(sync());
    return active;
  }

  // Merges this book's entry with the WebDAV copy in both directions and
  // returns the active bookmarks. Without WebDAV it just returns local ones.
  Future<List<ReaderBookmark>> sync() {
    // One sync at a time app-wide: each builds its own client, so the
    // service's lock alone would not stop two read-modify-writes overlapping.
    final next = _syncQueue.then((_) => _sync());
    _syncQueue = next.then((_) {}, onError: (_) {});
    return next;
  }

  static Future<void> _syncQueue = Future.value();

  Future<List<ReaderBookmark>> _sync() async {
    final webDav = WebDavSyncService.fromPrefs(prefs, logger);
    if (webDav == null) return active;

    try {
      List<ReaderBookmark>? merged;
      await webDav.updateJsonFile(webDavFileName, (current) {
        final remoteRaw = current[_webDavKey];
        final remote =
            remoteRaw is List
                ? remoteRaw.map(ReaderBookmark.fromJson).nonNulls.toList()
                : <ReaderBookmark>[];
        final result = mergeBookmarks(_all(), remote);
        merged = result;
        if (_sameBookmarks(result, mergeBookmarks(remote, const []))) {
          return null;
        }
        if (result.isEmpty) {
          current.remove(_webDavKey);
        } else {
          current[_webDavKey] = result.map((b) => b.toJson()).toList();
        }
        return current;
      });
      // Merged again with what is stored now, so a bookmark added while the
      // request was in flight survives.
      final result = merged;
      if (result != null) await _save(mergeBookmarks(_all(), result));
    } catch (e) {
      logger.w('Could not sync bookmarks with WebDAV: $e');
    }
    return active;
  }
}
