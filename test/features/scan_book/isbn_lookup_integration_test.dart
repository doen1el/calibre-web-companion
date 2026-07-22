@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/scan_book/data/datasources/isbn_remote_datasource.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/bnf_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/google_books_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/open_library_provider.dart';

const String _frenchIsbn = '9782070612758';

final Logger _silent = Logger(level: Level.off);

void main() {
  test('BnF resolves a French edition', () async {
    final book = await BnfProvider(logger: _silent).lookup(_frenchIsbn);

    expect(book, isNotNull);
    expect(book!.title.toLowerCase(), contains('petit prince'));
    expect(book.authors.first, contains('Saint-Exupéry'));
    expect(book.languageCode, 'fr');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'Open Library resolves the same edition',
    () async {
      final book = await OpenLibraryProvider(
        logger: _silent,
      ).lookup(_frenchIsbn);

      expect(book, isNotNull);
      expect(book!.title.toLowerCase(), contains('prince'));
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'Google Books resolves the same edition',
    () async {
      try {
        final book = await GoogleBooksProvider(
          logger: _silent,
        ).lookup(_frenchIsbn);
        expect(book, isNotNull);
      } catch (e) {
        expect(e.toString(), contains('429'));
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'the merged lookup fills cover and language',
    () async {
      final book = await IsbnRemoteDataSource(
        logger: _silent,
        providerOverride: [
          OpenLibraryProvider(logger: _silent),
          BnfProvider(logger: _silent),
        ],
      ).lookupByIsbn(_frenchIsbn);

      expect(book, isNotNull);
      expect(book!.title.toLowerCase(), contains('prince'));
      expect(book.authors, isNotEmpty);
      expect(book.coverUrl, isNotNull);
      expect(book.languageCode, 'fr');
      expect(book.sources.length, 2);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
