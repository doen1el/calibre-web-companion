import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';

class PlaceholderBookDataSource {
  final ApiService apiService;
  final http.Client client;
  final Logger logger;

  PlaceholderBookDataSource({
    required this.apiService,
    http.Client? client,
    Logger? logger,
  }) : client = client ?? http.Client(),
       logger = logger ?? Logger();

  Future<bool> createPlaceholder(IsbnBook book) async {
    logger.i(
      'Creating placeholder book for ISBN ${book.isbn} ("${book.title}")',
    );

    final coverBytes = await _fetchCover(book.coverUrl);
    final epubBytes = _buildEpub(book, coverBytes);

    final dir = await getTemporaryDirectory();
    final safeTitle =
        book.title.isEmpty
            ? 'book_${book.isbn}'
            : book.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    final file = File(
      p.join(dir.path, '${safeTitle.isEmpty ? book.isbn : safeTitle}.epub'),
    );
    await file.writeAsBytes(epubBytes, flush: true);
    logger.d(
      'Wrote placeholder EPUB (${epubBytes.length} bytes) to ${file.path}',
    );

    try {
      final result = await apiService.uploadFile(
        file: file,
        endpoint: '/upload',
        timeoutSeconds: 60,
      );
      if (result['success'] == true) {
        logger.i('Placeholder book uploaded for ISBN ${book.isbn}');
        return true;
      }
      logger.e('Placeholder upload failed: ${result['error']}');
      throw Exception(result['error'] ?? 'Upload failed');
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<List<int>?> _fetchCover(String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty) return null;
    try {
      final response = await client
          .get(Uri.parse(coverUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        logger.d('Fetched cover (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      }
      logger.w('Cover fetch returned ${response.statusCode}');
    } catch (e) {
      logger.w('Failed to fetch cover: $e');
    }
    return null;
  }

  List<int> _buildEpub(IsbnBook book, List<int>? coverBytes) {
    final archive = Archive();

    void addFile(String name, List<int> bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final mimetype = utf8.encode('application/epub+zip');
    final mimetypeFile = ArchiveFile('mimetype', mimetype.length, mimetype)
      ..compress = false;
    archive.addFile(mimetypeFile);

    addFile('META-INF/container.xml', utf8.encode(_containerXml));

    final hasCover = coverBytes != null && coverBytes.isNotEmpty;
    if (hasCover) {
      addFile('OEBPS/cover.jpg', coverBytes);
    }

    addFile('OEBPS/content.opf', utf8.encode(_contentOpf(book, hasCover)));
    addFile('OEBPS/toc.ncx', utf8.encode(_tocNcx(book)));
    addFile('OEBPS/title.xhtml', utf8.encode(_titlePage(book)));

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw Exception('Failed to encode placeholder EPUB');
    }
    return encoded;
  }

  String get _containerXml => '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

  String _contentOpf(IsbnBook book, bool hasCover) {
    final authors =
        book.authors.isEmpty
            ? '<dc:creator opf:role="aut">Unknown</dc:creator>'
            : book.authors
                .map(
                  (a) => '<dc:creator opf:role="aut">${_esc(a)}</dc:creator>',
                )
                .join('\n    ');
    final subjects = book.subjects
        .take(10)
        .map((s) => '<dc:subject>${_esc(s)}</dc:subject>')
        .join('\n    ');
    final isoDate = _normalizeDate(book.publishDate);
    final date = isoDate != null ? '<dc:date>$isoDate</dc:date>' : '';
    final publisher =
        book.publisher.isNotEmpty
            ? '<dc:publisher>${_esc(book.publisher)}</dc:publisher>'
            : '';
    final coverMeta =
        hasCover ? '<meta name="cover" content="cover-image"/>' : '';
    final coverItem =
        hasCover
            ? '<item id="cover-image" href="cover.jpg" media-type="image/jpeg"/>'
            : '';
    final description =
        book.description.isNotEmpty
            ? '<dc:description>${_esc(book.description)}</dc:description>'
            : '';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${_esc(book.title.isEmpty ? book.isbn : book.title)}</dc:title>
    $authors
    <dc:identifier id="bookid" opf:scheme="ISBN">${_esc(book.isbn)}</dc:identifier>
    <dc:identifier opf:scheme="ISBN">${_esc(book.isbn)}</dc:identifier>
    <dc:language>${book.languageCode}</dc:language>
    $publisher
    $date
    $description
    $subjects
    $coverMeta
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>
    $coverItem
  </manifest>
  <spine toc="ncx">
    <itemref idref="title"/>
  </spine>
</package>''';
  }

  String _tocNcx(IsbnBook book) => '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="ISBN:${_esc(book.isbn)}"/>
  </head>
  <docTitle><text>${_esc(book.title.isEmpty ? book.isbn : book.title)}</text></docTitle>
  <navMap>
    <navPoint id="title" playOrder="1">
      <navLabel><text>${_esc(book.title.isEmpty ? book.isbn : book.title)}</text></navLabel>
      <content src="title.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

  String _titlePage(IsbnBook book) {
    final authorLine =
        book.authors.isNotEmpty
            ? '<p class="author">${_esc(book.authorsLabel)}</p>'
            : '';
    final coverImg =
        (book.coverUrl != null && book.coverUrl!.isNotEmpty)
            ? '<div><img src="cover.jpg" alt="Cover"/></div>'
            : '';
    final descriptionBlock =
        book.description.isNotEmpty ? '<p>${_esc(book.description)}</p>' : '';
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${_esc(book.title)}</title></head>
<body>
  $coverImg
  <h1>${_esc(book.title.isEmpty ? book.isbn : book.title)}</h1>
  $authorLine
  <p>ISBN: ${_esc(book.isbn)}</p>
  $descriptionBlock
  <p><em>Placeholder created from scanned metadata.</em></p>
</body>
</html>''';
  }

  String? _normalizeDate(String raw) {
    if (raw.trim().isEmpty) return null;

    final yearOnly = RegExp(r'^\s*(\d{4})\s*$').firstMatch(raw);
    if (yearOnly != null) {
      return '${yearOnly.group(1)}-01-01';
    }

    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.day.toString().padLeft(2, '0')}';
    }

    final anyYear = RegExp(r'(\d{4})').firstMatch(raw);
    if (anyYear != null) {
      return '${anyYear.group(1)}-01-01';
    }

    return null;
  }

  String _esc(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
