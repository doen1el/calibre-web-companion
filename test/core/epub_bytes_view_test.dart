import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
// epubx is pulled in via cosmos_epub (vendored override).
// ignore: depend_on_referenced_packages
import 'package:epubx/epubx.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _minimalEpub() {
  final archive = Archive();
  void add(String name, String content) {
    final data = utf8.encode(content);
    archive.addFile(ArchiveFile(name, data.length, data));
  }

  add('mimetype', 'application/epub+zip');
  add(
    'META-INF/container.xml',
    '<?xml version="1.0"?><container version="1.0" '
        'xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles>'
        '<rootfile full-path="content.opf" '
        'media-type="application/oebps-package+xml"/></rootfiles></container>',
  );
  add(
    'content.opf',
    '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" '
        'version="2.0" unique-identifier="id"><metadata '
        'xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>T</dc:title>'
        '<dc:identifier id="id">x</dc:identifier></metadata><manifest>'
        '<item id="c1" href="c1.xhtml" media-type="application/xhtml+xml"/>'
        '</manifest><spine><itemref idref="c1"/></spine></package>',
  );
  add('c1.xhtml', '<html><body><p>Hi</p></body></html>');
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  // Platform channels can hand back a view with a non-zero offset into a
  // larger buffer; `bytes.buffer.asUint8List()` would then include the prefix.
  final epub = _minimalEpub();
  final backing = Uint8List(epub.length + 7)
    ..setRange(7, 7 + epub.length, epub);
  final view = Uint8List.view(backing.buffer, 7, epub.length);

  test('reads an EPUB passed as an offset view', () async {
    final book = await EpubReader.readBook(view);
    expect(book.Title, 'T');
  });

  test('the whole backing buffer is not the book', () {
    expect(view.buffer.asUint8List().length, isNot(epub.length));
  });
}
