import 'package:calibre_web_companion/core/utils/book_drop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migrateBookDropUrl', () {
    test('falls back to bookdrop.cc when unset', () {
      expect(migrateBookDropUrl(null), defaultBookDropUrl);
      expect(migrateBookDropUrl('  '), defaultBookDropUrl);
    });

    test('replaces the retired send.djazz.se instance', () {
      expect(migrateBookDropUrl('https://send.djazz.se'), defaultBookDropUrl);
      expect(migrateBookDropUrl('https://send.djazz.se/'), defaultBookDropUrl);
      expect(migrateBookDropUrl('http://SEND.djazz.se'), defaultBookDropUrl);
    });

    test('keeps self-hosted instances', () {
      expect(
        migrateBookDropUrl('https://books.example.com'),
        'https://books.example.com',
      );
    });
  });

  test('builds upload and receive urls without double slashes', () {
    expect(
      bookDropUploadUrl('https://bookdrop.cc/'),
      'https://bookdrop.cc/upload',
    );
    expect(
      bookDropReceiveUrl('https://bookdrop.cc'),
      'https://bookdrop.cc/receive',
    );
  });
}
