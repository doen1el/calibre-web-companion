import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:calibre_web_companion/core/utils/upload_file_name.dart';

Uint8List _bytes(List<int> prefix, {int padTo = 0}) {
  final list = List<int>.from(prefix);
  while (list.length < padTo) {
    list.add(0);
  }
  return Uint8List.fromList(list);
}

Uint8List _ascii(String text, {int padTo = 0}) =>
    _bytes(text.codeUnits, padTo: padTo);

/// An EPUB starts with a zip entry holding the uncompressed mimetype
Uint8List _epubHead() {
  final head = <int>[0x50, 0x4B, 0x03, 0x04];
  while (head.length < 30) {
    head.add(0);
  }
  head.addAll('mimetypeapplication/epub+zip'.codeUnits);
  return Uint8List.fromList(head);
}

void main() {
  group('detectExtension', () {
    test('recognizes an EPUB by its mimetype entry', () {
      expect(UploadFileName.detectExtension(_epubHead()), 'epub');
    });

    test('recognizes an EPUB by its container entry', () {
      final head = <int>[0x50, 0x4B, 0x03, 0x04];
      head.addAll('META-INF/container.xml'.codeUnits);
      expect(UploadFileName.detectExtension(Uint8List.fromList(head)), 'epub');
    });

    test('recognizes PDF, MOBI and DJVU', () {
      expect(UploadFileName.detectExtension(_ascii('%PDF-1.7')), 'pdf');
      expect(
        UploadFileName.detectExtension(
          Uint8List.fromList([
            ..._ascii('TITLE', padTo: 60),
            ...'BOOKMOBI'.codeUnits,
          ]),
        ),
        'mobi',
      );
      expect(UploadFileName.detectExtension(_ascii('AT&TFORM')), 'djvu');
    });

    test('does not guess for a plain zip', () {
      final zip = _bytes([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00], padTo: 64);
      expect(UploadFileName.detectExtension(zip), isNull);
    });
  });

  group('resolve', () {
    test('keeps a proper name from the picker', () {
      expect(
        UploadFileName.resolve('The Hobbit.epub', head: _epubHead()),
        'The_Hobbit.epub',
      );
    });

    test('adds the extension when the provider dropped it', () {
      // What a cloud provider hands out when DISPLAY_NAME is missing
      expect(
        UploadFileName.resolve('acc=1;doc=12345', head: _epubHead()),
        'acc_1_doc_12345.epub',
      );
      expect(
        UploadFileName.resolve('unamed', head: _epubHead()),
        'unamed.epub',
      );
    });

    test('sanitizes characters calibre-web rejects', () {
      expect(
        UploadFileName.resolve('Der Prozeß (1925) [v2].epub'),
        'Der_Proze_1925_v2.epub',
      );
    });

    test('leaves the name without extension when nothing is detected', () {
      final name = UploadFileName.resolve(
        'document',
        head: _bytes([0x00, 0x01, 0x02], padTo: 64),
      );
      expect(UploadFileName.hasExtension(name), isFalse);
    });

    test('strips path segments', () {
      expect(
        UploadFileName.resolve('/cache/file_picker/1700000/book.epub'),
        'book.epub',
      );
    });
  });

  group('hasExtension', () {
    test('detects missing extensions', () {
      expect(UploadFileName.hasExtension('book.epub'), isTrue);
      expect(UploadFileName.hasExtension('book'), isFalse);
      expect(UploadFileName.hasExtension('book.'), isFalse);
      expect(UploadFileName.hasExtension('.hidden'), isFalse);
    });
  });
}
