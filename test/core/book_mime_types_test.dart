import 'package:calibre_web_companion/core/utils/book_mime_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bookFormatFromAcquisition', () {
    test('resolves known mime types', () {
      expect(
        bookFormatFromAcquisition(mimeType: 'application/epub+zip'),
        'epub',
      );
      expect(bookFormatFromAcquisition(mimeType: 'image/vnd.djvu'), 'djvu');
      expect(
        bookFormatFromAcquisition(mimeType: 'text/plain; charset=utf-8'),
        'txt',
      );
    });

    test('falls back to the download url for unknown mime types', () {
      expect(
        bookFormatFromAcquisition(
          mimeType: 'application/octet-stream',
          href: '/opds/download/42/djvu/',
        ),
        'djvu',
      );
      expect(
        bookFormatFromAcquisition(href: 'https://host/files/book.djvu'),
        'djvu',
      );
    });

    test('returns null when neither mime type nor url tell a format', () {
      expect(bookFormatFromAcquisition(), isNull);
      expect(
        bookFormatFromAcquisition(
          mimeType: 'application/octet-stream',
          href: '/opds/download/42/',
        ),
        isNull,
      );
    });
  });
}
