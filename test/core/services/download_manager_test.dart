import 'dart:convert';
import 'dart:io';

import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dm_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  String touch(String name) {
    final f = File('${dir.path}/$name')..writeAsStringSync('x');
    return f.path;
  }

  Future<DownloadManager> create([Map<String, Object>? stored]) async {
    SharedPreferences.setMockInitialValues(
      stored == null ? {} : {'downloaded_books_map': json.encode(stored)},
    );
    final dm = DownloadManager(
      prefs: await SharedPreferences.getInstance(),
      logger: Logger(level: Level.off),
    );
    await dm.initialize();
    return dm;
  }

  test('migrates legacy single-path entries', () async {
    final epub = touch('Book.epub');
    final dm = await create({'u1': epub});

    expect(dm.downloadedFormats('u1'), {'epub'});
    expect(dm.getBookPath('u1', format: 'EPUB'), epub);
    expect(dm.allDownloads, {'u1': epub});
  });

  test('keeps one entry per format', () async {
    final dm = await create();
    final epub = touch('Book.epub');
    final m4b = touch('Book.m4b');
    await dm.registerDownload('u1', epub);
    await dm.registerDownload('u1', m4b);

    expect(dm.downloadedFormats('u1'), {'epub', 'm4b'});
    expect(dm.getBookPath('u1', format: 'm4b'), m4b);
    expect(dm.getBookPath('u1', format: 'epub'), epub);
  });

  test('allBookPaths lists every format of a book', () async {
    final dm = await create();
    final epub = touch('Book.epub');
    final m4b = touch('Book.m4b');
    await dm.registerDownload('u1', epub);
    await dm.registerDownload('u1', m4b);

    expect(dm.allBookPaths('u1'), unorderedEquals([epub, m4b]));
    expect(dm.allBookPaths('missing'), isEmpty);
  });

  test('format lookup never returns another format', () async {
    final dm = await create();
    await dm.registerDownload('u1', touch('Book.m4b'));

    expect(dm.getBookPath('u1', format: 'epub'), isNull);
  });

  test('prunes missing formats but keeps the book', () async {
    final epub = touch('Book.epub');
    final dm = await create({
      'u1': {'epub': epub, 'm4b': '${dir.path}/gone.m4b'},
      'u2': '${dir.path}/gone.epub',
    });

    expect(dm.downloadedFormats('u1'), {'epub'});
    expect(dm.isBookDownloaded('u2'), isFalse);

    File(epub).deleteSync();
    expect(await dm.checkFileExistence('u1'), isFalse);
    expect(dm.isBookDownloaded('u1'), isFalse);
  });

  test('content URIs resolve the extension from the last segment', () async {
    final dm = await create();
    const uri =
        'content://com.android.externalstorage.documents/document/'
        'primary%3ADownload%2FAuthor%2FTitle.epub';
    await dm.registerDownload('u1', uri);

    expect(dm.downloadedFormats('u1'), {'epub'});
  });
}
