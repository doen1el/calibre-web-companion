import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:calibre_web_companion/core/services/reader_cache_service.dart';
import 'package:calibre_web_companion/features/reader/data/internal_reader_formats.dart';
import 'package:calibre_web_companion/features/reader/data/page_progress_store.dart';
import 'package:calibre_web_companion/features/reader/presentation/pages/comic_reader_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InternalReaderFormats', () {
    test('supports EPUB, PDF and CBZ only', () {
      expect(InternalReaderFormats.isSupported('EPUB'), isTrue);
      expect(InternalReaderFormats.isSupported('pdf'), isTrue);
      expect(InternalReaderFormats.isSupported('cbz'), isTrue);
      expect(InternalReaderFormats.isSupported('mobi'), isFalse);
      expect(InternalReaderFormats.isPageBased('epub'), isFalse);
    });

    test('checks the file signature against the format', () {
      final pdf = Uint8List.fromList('%PDF-1.7'.codeUnits);
      final zip = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
      final html = Uint8List.fromList('<html>'.codeUnits);

      expect(InternalReaderFormats.bytesMatch('pdf', pdf), isTrue);
      expect(InternalReaderFormats.bytesMatch('pdf', zip), isFalse);
      expect(InternalReaderFormats.bytesMatch('cbz', zip), isTrue);
      expect(InternalReaderFormats.bytesMatch('epub', html), isFalse);
    });
  });

  group('ComicReaderPage pages', () {
    test('sorts page names naturally', () {
      final names = ['p10.jpg', 'p2.jpg', 'p1.jpg'];
      names.sort(ComicReaderPage.naturalCompare);
      expect(names, ['p1.jpg', 'p2.jpg', 'p10.jpg']);
    });

    test('keeps only images and skips metadata files', () {
      final archive = Archive();
      for (final name in [
        'ComicInfo.xml',
        '__MACOSX/._01.jpg',
        'ch1/.hidden.png',
        'ch1/10.png',
        'ch1/9.JPG',
      ]) {
        archive.addFile(ArchiveFile(name, 1, [0]));
      }

      final pages = ComicReaderPage.imagePages(archive);
      expect(pages.map((f) => f.name), ['ch1/9.JPG', 'ch1/10.png']);
    });
  });

  group('PageProgress', () {
    test('maps the last page to 100%', () {
      const progress = PageProgress(page: 9, pageCount: 10, timestamp: 0);
      expect(progress.percentage, 100);
      expect(
        const PageProgress(page: 0, pageCount: 10, timestamp: 0).percentage,
        0,
      );
    });

    test('round-trips through JSON', () {
      const progress = PageProgress(page: 4, pageCount: 20, timestamp: 42);
      final decoded = PageProgress.fromJson(progress.toJson());
      expect(decoded?.page, 4);
      expect(decoded?.pageCount, 20);
      expect(decoded?.timestamp, 42);
      expect(PageProgress.fromJson('not json'), isNull);
    });
  });

  group('ReaderCacheService', () {
    late Directory tempDir;
    late ReaderCacheService cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({ReaderCacheService.limitKey: 1});
      tempDir = await Directory.systemTemp.createTemp('reader_cache_test');
      cache = ReaderCacheService(
        prefs: await SharedPreferences.getInstance(),
        logger: Logger(level: Level.off),
        baseDirectory: () async => tempDir,
      );
    });

    tearDown(() => tempDir.delete(recursive: true));

    Uint8List bytesOf(int kb) => Uint8List(kb * 1024);

    test('stores and finds a book by uuid and format', () async {
      final path = await cache.store('abc-1', 'pdf', bytesOf(10));
      expect(path, isNotNull);
      expect((await cache.find('abc-1', 'pdf'))?.path, path);
      expect(await cache.find('abc-1', 'epub'), isNull);

      final entries = await cache.entries();
      expect(entries.single.uuid, 'abc-1');
      expect(entries.single.format, 'pdf');
    });

    test('evicts the least recently used book over the limit', () async {
      final oldest = await cache.store('old', 'epub', bytesOf(400));
      await File(
        oldest!,
      ).setLastModified(DateTime.now().subtract(const Duration(days: 2)));
      final middle = await cache.store('mid', 'epub', bytesOf(400));
      await File(
        middle!,
      ).setLastModified(DateTime.now().subtract(const Duration(days: 1)));

      await cache.store('new', 'epub', bytesOf(400));

      final uuids = (await cache.entries()).map((e) => e.uuid).toSet();
      expect(uuids, {'mid', 'new'});
    });

    test('does not cache a book larger than the limit', () async {
      expect(await cache.store('big', 'pdf', bytesOf(1100)), isNull);
      expect(await cache.entries(), isEmpty);
    });

    test('disabling clears the cache', () async {
      await cache.store('abc', 'cbz', bytesOf(10));
      await cache.setEnabled(false);
      expect(await cache.entries(), isEmpty);
      expect(await cache.store('abc', 'cbz', bytesOf(10)), isNull);
    });
  });
}
