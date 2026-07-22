import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/scan_book/data/datasources/isbn_remote_datasource.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/bnf_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/google_books_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_source_settings.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_utils.dart';

const String _isbn = '9782070643028';

class _FakeProvider extends IsbnMetadataProvider {
  @override
  final IsbnMetadataSource source;
  final IsbnBook? result;
  final Object? error;

  _FakeProvider(this.source, {this.result, this.error});

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    if (error != null) throw error!;
    return result;
  }
}

IsbnRemoteDataSource _dataSource(List<IsbnMetadataProvider> providers) {
  return IsbnRemoteDataSource(
    logger: Logger(level: Level.off),
    providerOverride: providers,
    client: MockClient((request) async => http.Response('', 404)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isbn utils', () {
    test('converts ISBN-10 to ISBN-13', () {
      expect(toIsbn13('0306406152'), '9780306406157');
      expect(toIsbn13('2070643026'), '9782070643028');
      expect(toIsbn13(_isbn), _isbn);
      expect(toIsbn13('123'), isNull);
    });

    test('converts ISBN-13 back to ISBN-10', () {
      expect(toIsbn10('9782253009689'), '2253009687');
      expect(toIsbn10('9782070368228'), '207036822X');
      expect(toIsbn10('2253009687'), '2253009687');
      expect(toIsbn10('9791234567896'), isNull);
    });

    test('falls back to the ISBN registration group for the language', () {
      String lang(String isbn) => IsbnBook(isbn: isbn, title: 't').languageCode;

      expect(lang('9782070612758'), 'fr');
      expect(lang('9783442267743'), 'de');
      expect(lang('9788408163923'), 'es');
      expect(lang('9789630000000'), 'hu');
      expect(lang('9780306406157'), 'en');
      expect(lang('nonsense'), 'und');
    });

    test('a reported language beats the ISBN group', () {
      const book = IsbnBook(isbn: '9782070612758', title: 't', language: 'eng');

      expect(book.languageCode, 'en');
    });

    test('normalizes language codes', () {
      expect(normalizeLanguageCode('fre'), 'fr');
      expect(normalizeLanguageCode('FRA'), 'fr');
      expect(normalizeLanguageCode('en-GB'), 'en');
      expect(normalizeLanguageCode('klingon'), '');
    });

    test('flips catalogue author names and drops life dates', () {
      expect(
        cleanCatalogAuthor('Saint-Exupéry, Antoine de (1900-1944)'),
        'Antoine de Saint-Exupéry',
      );
      expect(cleanCatalogAuthor('J. K. Rowling'), 'J. K. Rowling');
    });
  });

  group('merging', () {
    test('fills gaps without overwriting existing fields', () {
      const primary = IsbnBook(
        isbn: _isbn,
        title: 'Le Petit Prince',
        description: 'Short note.',
        subjects: ['Fiction'],
        sources: [IsbnMetadataSource.openLibrary],
      );
      const secondary = IsbnBook(
        isbn: _isbn,
        title: 'Le petit prince (poche)',
        authors: ['Antoine de Saint-Exupéry'],
        publisher: 'Gallimard',
        coverUrl: 'https://example.org/cover.jpg',
        pageCount: 96,
        subjects: ['Fiction', 'Conte'],
        description: 'A much longer synopsis of the story.',
        language: 'fre',
        sources: [IsbnMetadataSource.bnf],
      );

      final merged = primary.mergeWith(secondary);

      expect(merged.title, 'Le Petit Prince');
      expect(merged.authors, ['Antoine de Saint-Exupéry']);
      expect(merged.publisher, 'Gallimard');
      expect(merged.coverUrl, 'https://example.org/cover.jpg');
      expect(merged.pageCount, 96);
      expect(merged.description, 'A much longer synopsis of the story.');
      expect(merged.subjects, ['Fiction', 'Conte']);
      expect(merged.languageCode, 'fr');
      expect(merged.sources, [
        IsbnMetadataSource.openLibrary,
        IsbnMetadataSource.bnf,
      ]);
    });
  });

  group('aggregation', () {
    test('merges answers from every source', () async {
      final book = await _dataSource([
        _FakeProvider(
          IsbnMetadataSource.openLibrary,
          result: const IsbnBook(
            isbn: _isbn,
            title: 'Le Petit Prince',
            sources: [IsbnMetadataSource.openLibrary],
          ),
        ),
        _FakeProvider(
          IsbnMetadataSource.bnf,
          result: const IsbnBook(
            isbn: _isbn,
            title: 'Le petit prince',
            authors: ['Antoine de Saint-Exupéry'],
            sources: [IsbnMetadataSource.bnf],
          ),
        ),
      ]).lookupByIsbn(_isbn);

      expect(book, isNotNull);
      expect(book!.title, 'Le Petit Prince');
      expect(book.authors, ['Antoine de Saint-Exupéry']);
      expect(book.sources.length, 2);
    });

    test('the configured order decides which title wins', () async {
      IsbnBook openLibrary() => const IsbnBook(
        isbn: _isbn,
        title: 'The Little Prince',
        sources: [IsbnMetadataSource.openLibrary],
      );
      IsbnBook bnf() => const IsbnBook(
        isbn: _isbn,
        title: 'Le petit prince',
        sources: [IsbnMetadataSource.bnf],
      );

      final defaultOrder = await _dataSource([
        _FakeProvider(IsbnMetadataSource.openLibrary, result: openLibrary()),
        _FakeProvider(IsbnMetadataSource.bnf, result: bnf()),
      ]).lookupByIsbn(_isbn);

      final bnfFirst = await _dataSource([
        _FakeProvider(IsbnMetadataSource.bnf, result: bnf()),
        _FakeProvider(IsbnMetadataSource.openLibrary, result: openLibrary()),
      ]).lookupByIsbn(_isbn);

      expect(defaultOrder!.title, 'The Little Prince');
      expect(bnfFirst!.title, 'Le petit prince');
    });

    test('a failing source does not hide a working one', () async {
      final book = await _dataSource([
        _FakeProvider(IsbnMetadataSource.openLibrary, error: Exception('down')),
        _FakeProvider(
          IsbnMetadataSource.googleBooks,
          result: const IsbnBook(
            isbn: _isbn,
            title: 'Le Petit Prince',
            sources: [IsbnMetadataSource.googleBooks],
          ),
        ),
      ]).lookupByIsbn(_isbn);

      expect(book?.title, 'Le Petit Prince');
    });

    test('edition-level titles beat work-level ones', () async {
      final book = await _dataSource([
        _FakeProvider(
          IsbnMetadataSource.openLibrary,
          result: const IsbnBook(
            isbn: _isbn,
            title: 'The Little Prince',
            authors: ['Antoine de Saint-Exupery'],
            sources: [IsbnMetadataSource.openLibrary],
            approximate: true,
          ),
        ),
        _FakeProvider(
          IsbnMetadataSource.bnf,
          result: const IsbnBook(
            isbn: _isbn,
            title: 'Le petit prince',
            sources: [IsbnMetadataSource.bnf],
          ),
        ),
      ]).lookupByIsbn(_isbn);

      expect(book!.title, 'Le petit prince');
      expect(book.authors, ['Antoine de Saint-Exupery']);
    });

    test('returns null when no catalogue knows the ISBN', () async {
      final book = await _dataSource([
        _FakeProvider(IsbnMetadataSource.openLibrary),
        _FakeProvider(IsbnMetadataSource.bnf),
      ]).lookupByIsbn(_isbn);

      expect(book, isNull);
    });

    test('throws when every source errored out', () {
      expect(
        _dataSource([
          _FakeProvider(IsbnMetadataSource.openLibrary, error: Exception('a')),
          _FakeProvider(IsbnMetadataSource.bnf, error: Exception('b')),
        ]).lookupByIsbn(_isbn),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects malformed ISBNs before hitting the network', () async {
      expect(await _dataSource([]).lookupByIsbn('12345'), isNull);
    });
  });

  group('parsing', () {
    test('Google Books volume', () async {
      final provider = GoogleBooksProvider(
        logger: Logger(level: Level.off),
        client: MockClient(
          (request) async => http.Response.bytes(
            utf8.encode(
              json.encode({
                'items': [
                  {
                    'volumeInfo': {
                      'title': 'Le Petit Prince',
                      'authors': ['Antoine de Saint-Exupéry'],
                      'publisher': 'Gallimard',
                      'publishedDate': '1999-02-01',
                      'description': 'Un conte <b>poétique</b>.',
                      'pageCount': 96,
                      'categories': ['Juvenile Fiction'],
                      'language': 'fr',
                      'imageLinks': {
                        'thumbnail':
                            'http://books.google.com/books?id=1&edge=curl',
                      },
                    },
                  },
                ],
              }),
            ),
            200,
          ),
        ),
      );

      final book = await provider.lookup(_isbn);

      expect(book!.title, 'Le Petit Prince');
      expect(book.authors, ['Antoine de Saint-Exupéry']);
      expect(book.pageCount, 96);
      expect(book.description, 'Un conte poétique.');
      expect(book.coverUrl, 'https://books.google.com/books?id=1');
      expect(book.languageCode, 'fr');
    });

    test('BnF SRU dublincore record', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<srw:searchRetrieveResponse xmlns:srw="http://www.loc.gov/zing/srw/">
  <srw:numberOfRecords>1</srw:numberOfRecords>
  <srw:records><srw:record><srw:recordData>
    <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:identifier>http://catalogue.bnf.fr/ark:/12148/cb41023439w</dc:identifier>
      <dc:title>Le petit prince / Antoine de Saint-Exup&#233;ry ; avec des aquarelles de l'auteur</dc:title>
      <dc:creator>Saint-Exup&#233;ry, Antoine de (1900-1944). Auteur du texte</dc:creator>
      <dc:publisher>Gallimard (Paris)</dc:publisher>
      <dc:date>2007</dc:date>
      <dc:description>Collection : Folio junior ; 100</dc:description>
      <dc:identifier>ISBN 9782070612758</dc:identifier>
      <dc:description>Code &#224; barres commercial : EAN 9782070612758</dc:description>
      <dc:format>1 vol. (113 p.) : ill., couv. ill. en coul. ; 18 cm</dc:format>
      <dc:language>fre</dc:language>
      <dc:subject>Conte</dc:subject>
    </oai_dc:dc>
  </srw:recordData></srw:record></srw:records>
</srw:searchRetrieveResponse>''';

      final provider = BnfProvider(
        logger: Logger(level: Level.off),
        client: MockClient(
          (request) async => http.Response.bytes(utf8.encode(xml), 200),
        ),
      );

      final book = await provider.lookup(_isbn);

      expect(book!.title, 'Le petit prince');
      expect(book.authors, ['Antoine de Saint-Exupéry']);
      expect(book.publisher, 'Gallimard');
      expect(book.publishDate, '2007');
      expect(book.pageCount, 113);
      expect(book.subjects, ['Conte']);
      expect(book.languageCode, 'fr');
      expect(book.description, isEmpty);
    });

    test('BnF record prefers the author over the translator', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<srw:searchRetrieveResponse xmlns:srw="http://www.loc.gov/zing/srw/">
  <srw:records><srw:record><srw:recordData>
    <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title>Le proscrit / Simon R. Green ; trad. de l'anglais par Arnaud Mousnier-Lompr&#233;</dc:title>
      <dc:creator>Mousnier-Lompr&#233;, Arnaud (1965-....). Traducteur</dc:creator>
      <dc:creator>Green, Simon R. (1955-....). Auteur du texte</dc:creator>
    </oai_dc:dc>
  </srw:recordData></srw:record></srw:records>
</srw:searchRetrieveResponse>''';

      final provider = BnfProvider(
        logger: Logger(level: Level.off),
        client: MockClient(
          (request) async => http.Response.bytes(utf8.encode(xml), 200),
        ),
      );

      final book = await provider.lookup(_isbn);

      expect(book!.authors, ['Simon R. Green']);
    });

    test('BnF query asks for both ISBN forms', () async {
      late Uri captured;
      final provider = BnfProvider(
        logger: Logger(level: Level.off),
        client: MockClient((request) async {
          captured = request.url;
          return http.Response('', 200);
        }),
      );

      await provider.lookup('9782253009689');

      expect(
        captured.queryParameters['query'],
        'bib.isbn all "9782253009689" or bib.isbn all "2253009687"',
      );
    });

    test('empty BnF result yields no book', () async {
      final provider = BnfProvider(
        logger: Logger(level: Level.off),
        client: MockClient(
          (request) async => http.Response(
            '<srw:searchRetrieveResponse><srw:numberOfRecords>0'
            '</srw:numberOfRecords></srw:searchRetrieveResponse>',
            200,
          ),
        ),
      );

      expect(await provider.lookup(_isbn), isNull);
    });
  });

  group('source settings', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to the keyless catalogues', () async {
      final settings = await IsbnSourceSettings.load();

      expect(settings.activeSources, [
        IsbnMetadataSource.openLibrary,
        IsbnMetadataSource.googleBooks,
        IsbnMetadataSource.bnf,
      ]);
    });

    test('persists a custom source order', () async {
      final initial = await IsbnSourceSettings.load();
      expect(initial.order.first, IsbnMetadataSource.openLibrary);

      await initial.withMovedSource(2, 0).save();

      final settings = await IsbnSourceSettings.load();
      expect(settings.order.first, IsbnMetadataSource.bnf);
      expect(settings.activeSources.first, IsbnMetadataSource.bnf);
      expect(settings.order.toSet(), IsbnMetadataSource.values.toSet());
      expect(settings.order.length, IsbnMetadataSource.values.length);
    });

    test('appends sources a stored order does not know yet', () async {
      SharedPreferences.setMockInitialValues({
        IsbnSourceSettings.orderKey: ['bnf', 'open_library', 'retired_source'],
      });

      final settings = await IsbnSourceSettings.load();

      expect(settings.order.take(2), [
        IsbnMetadataSource.bnf,
        IsbnMetadataSource.openLibrary,
      ]);
      expect(settings.order.toSet(), IsbnMetadataSource.values.toSet());
    });

    test('keeps credential sources inactive until a key is set', () async {
      await IsbnSourceSettings(enabled: {IsbnMetadataSource.hardcover}).save();

      var settings = await IsbnSourceSettings.load();
      expect(settings.activeSources, isEmpty);

      await settings
          .copyWith(credentials: {IsbnMetadataSource.hardcover: 'token'})
          .save();

      settings = await IsbnSourceSettings.load();
      expect(settings.activeSources, [IsbnMetadataSource.hardcover]);
    });
  });
}
