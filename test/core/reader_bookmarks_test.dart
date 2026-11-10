import 'dart:convert';
import 'dart:io';

import 'package:calibre_web_companion/features/reader/data/bookmark_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReaderBookmark _bookmark(
  String id, {
  int updatedAt = 1000,
  bool deleted = false,
  double percentage = 10,
}) => ReaderBookmark(
  id: id,
  page: 3,
  percentage: percentage,
  label: id,
  createdAt: 1000,
  updatedAt: updatedAt,
  deleted: deleted,
);

void main() {
  const now = 10 * 24 * 60 * 60 * 1000;

  group('mergeBookmarks', () {
    test('keeps bookmarks from both sides, sorted by position', () {
      final merged = mergeBookmarks(
        [_bookmark('a', percentage: 50)],
        [_bookmark('b', percentage: 20)],
        now: now,
      );
      expect(merged.map((b) => b.id), ['b', 'a']);
    });

    test('a later deletion wins over the older bookmark', () {
      final merged = mergeBookmarks(
        [_bookmark('a')],
        [_bookmark('a', updatedAt: 2000, deleted: true)],
        now: now,
      );
      expect(merged.single.deleted, isTrue);
    });

    test('a deletion wins a tie, so a stale copy cannot revive it', () {
      final merged = mergeBookmarks(
        [_bookmark('a', deleted: true)],
        [_bookmark('a')],
        now: now,
      );
      expect(merged.single.deleted, isTrue);
    });

    test('drops tombstones older than their lifetime', () {
      final old = now - BookmarkStore.tombstoneLifetime.inMilliseconds - 1;
      final merged = mergeBookmarks(
        [_bookmark('a', updatedAt: old, deleted: true)],
        [_bookmark('b', updatedAt: old)],
        now: now,
      );
      expect(merged.map((b) => b.id), ['b']);
    });
  });

  test('ReaderBookmark round-trips through JSON', () {
    const bookmark = ReaderBookmark(
      id: 'x',
      chapter: 4,
      chapterFraction: .25,
      percentage: 42.5,
      label: 'It was a dark night',
      createdAt: 1,
      updatedAt: 2,
    );
    final decoded = ReaderBookmark.fromJson(bookmark.toJson())!;
    expect(decoded.chapter, 4);
    expect(decoded.chapterFraction, .25);
    expect(decoded.page, isNull);
    expect(decoded.percentage, 42.5);
    expect(decoded.label, 'It was a dark night');
    expect(decoded.deleted, isFalse);
    expect(ReaderBookmark.fromJson({'page': 1}), isNull);
  });

  group('BookmarkStore without WebDAV', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    BookmarkStore store(String format) => BookmarkStore(
      prefs: prefs,
      logger: Logger(level: Level.off),
      bookUuid: 'uuid-1',
      format: format,
    );

    test('adds and removes bookmarks per format', () async {
      final pdf = store('PDF');
      final added = await pdf.add(
        ReaderBookmark.create(page: 7, percentage: 30, label: ''),
      );
      expect(added.single.page, 7);
      expect(store('cbz').active, isEmpty);

      final removed = await pdf.remove(added.single.id);
      expect(removed, isEmpty);
      expect(await store('pdf').sync(), isEmpty);
    });
  });

  group('BookmarkStore with WebDAV', () {
    late HttpServer server;
    final files = <String, List<int>>{};
    var writes = 0;

    setUp(() async {
      files.clear();
      writes = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final name = req.uri.pathSegments.last;
        if (req.method == 'OPTIONS') {
          req.response.statusCode = 200;
        } else if (req.method == 'PUT') {
          files[name] = await req.fold<List<int>>([], (a, b) => a..addAll(b));
          writes++;
          req.response.statusCode = 201;
        } else if (req.method == 'GET' && files.containsKey(name)) {
          req.response.add(files[name]!);
        } else {
          req.response.statusCode = 404;
        }
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    // Each "device" is a fresh preferences map pointing at the same server.
    Future<BookmarkStore> device() async {
      SharedPreferences.setMockInitialValues({
        'webdav_enabled': true,
        'webdav_url': 'http://127.0.0.1:${server.port}/',
        'webdav_username': 'u',
        'webdav_password': 'p',
      });
      return BookmarkStore(
        prefs: await SharedPreferences.getInstance(),
        logger: Logger(level: Level.off),
        bookUuid: 'uuid-1',
        format: 'epub',
      );
    }

    Map<String, dynamic> remote() =>
        jsonDecode(utf8.decode(files[BookmarkStore.webDavFileName]!))
            as Map<String, dynamic>;

    test('a bookmark and its deletion travel between devices', () async {
      final a = await device();
      final added = await a.add(
        ReaderBookmark.create(
          chapter: 2,
          chapterFraction: .5,
          percentage: 40,
          label: 'Call me Ishmael',
        ),
      );
      await a.sync();
      expect(
        (remote()['uuid-1@epub'] as List).single['label'],
        'Call me Ishmael',
      );

      final b = await device();
      final onB = await b.sync();
      expect(onB.single.id, added.single.id);
      expect(onB.single.chapterFraction, .5);

      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(await b.remove(onB.single.id), isEmpty);
      await b.sync();
      expect((remote()['uuid-1@epub'] as List).single['deleted'], isTrue);

      // Device A still holds the live copy locally; the newer tombstone wins.
      SharedPreferences.setMockInitialValues({
        'webdav_enabled': true,
        'webdav_url': 'http://127.0.0.1:${server.port}/',
        'reader_bookmarks_uuid-1_epub': jsonEncode(
          added.map((x) => x.toJson()).toList(),
        ),
      });
      final aAgain = BookmarkStore(
        prefs: await SharedPreferences.getInstance(),
        logger: Logger(level: Level.off),
        bookUuid: 'uuid-1',
        format: 'epub',
      );
      expect(await aAgain.sync(), isEmpty);
    });

    test('does not rewrite the remote file when nothing changed', () async {
      final a = await device();
      await a.add(ReaderBookmark.create(page: 1, percentage: 5, label: ''));
      await a.sync();
      final before = writes;
      await a.sync();
      await a.sync();
      expect(writes, before);
    });

    test('keeps other books in the shared file', () async {
      files[BookmarkStore.webDavFileName] = utf8.encode(
        jsonEncode({
          'other@pdf': [
            {
              'id': 'o',
              'page': 1,
              'percentage': 1,
              'label': '',
              'createdAt': 1,
            },
          ],
        }),
      );
      final a = await device();
      await a.add(ReaderBookmark.create(page: 1, percentage: 5, label: ''));
      await a.sync();
      expect(remote().keys, containsAll(['other@pdf', 'uuid-1@epub']));
    });
  });
}
