import 'package:calibre_web_companion/core/utils/file_name_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transliterateToAscii', () {
    test('matches the names the KOReader sync plugin writes (#226)', () {
      expect(
        transliterateToAscii('Wenn der Schläfer erwacht - H. G. Wells [497]'),
        'Wenn der Schlafer erwacht - H. G. Wells [497]',
      );
      expect(
        transliterateToAscii('Das Netz - Lilja Sigurðardóttir [540]'),
        'Das Netz - Lilja Sigurdardottir [540]',
      );
    });

    test('expands ligatures and sharp s', () {
      expect(transliterateToAscii('Straße Æsir Œuvre'), 'Strasse AEsir OEuvre');
    });

    test('drops combining marks of decomposed input', () {
      expect(transliterateToAscii('Schäfer'), 'Schafer');
    });

    test('keeps characters without a mapping', () {
      expect(transliterateToAscii('三体 Liu Cixin'), '三体 Liu Cixin');
    });
  });

  group('fileNameFromContentDisposition', () {
    test('decodes Calibre-Web NextGen headers', () {
      const header =
          'attachment; filename=2012%20-%20Die%20R%C3%BCckkehr%20-%20Steve%20Alten.epub; '
          "filename*=UTF-8''2012%20-%20Die%20R%C3%BCckkehr%20-%20Steve%20Alten.epub";
      expect(
        fileNameFromContentDisposition(header),
        '2012 - Die Rückkehr - Steve Alten.epub',
      );
    });

    test('prefers filename* over filename', () {
      expect(
        fileNameFromContentDisposition(
          "attachment; filename=\"fallback.epub\"; filename*=UTF-8''Sch%C3%A4fer.epub",
        ),
        'Schäfer.epub',
      );
    });

    test('reads a quoted plain filename containing a semicolon', () {
      expect(
        fileNameFromContentDisposition('attachment; filename="A; B.epub"'),
        'A; B.epub',
      );
    });

    test('drops any path and handles missing headers', () {
      expect(
        fileNameFromContentDisposition('attachment; filename="../x/y.epub"'),
        'y.epub',
      );
      expect(fileNameFromContentDisposition(null), isNull);
      expect(fileNameFromContentDisposition('inline'), isNull);
    });
  });

  group('stripBookExtension', () {
    test('removes the format extension only', () {
      expect(stripBookExtension('H. G. Wells.epub', 'epub'), 'H. G. Wells');
      expect(stripBookExtension('Book.kepub.epub', 'kepub'), 'Book');
      expect(stripBookExtension('Book.pdf', 'epub'), 'Book.pdf');
    });
  });
}
