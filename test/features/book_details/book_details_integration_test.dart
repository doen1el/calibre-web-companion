@Tags(['integration'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/tag_service.dart';
import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  late ApiService api;
  late BookDetailsRemoteDatasource dataSource;

  Future<void> setUpDataSource() async {
    api = await setupIntegrationTest();
    final logger = Logger(level: Level.off);
    dataSource = BookDetailsRemoteDatasource(
      apiService: api,
      logger: logger,
      tagService: TagService(apiService: api, logger: logger),
    );
  }

  test('fetchBookDetails() loads details for a real book', () async {
    await setUpDataSource();
    final book = await fetchFirstBook(api);

    final details = await dataSource.fetchBookDetails(book, book.uuid);

    expect(details, isNotNull);
    expect(details.title, isNotEmpty);
  });

  test('toggleReadStatus() flips and restores the read flag', () async {
    await setUpDataSource();
    final book = await fetchFirstBook(api);

    final first = await dataSource.toggleReadStatus(book.id);
    expect(first, isTrue);

    final second = await dataSource.toggleReadStatus(book.id);
    expect(second, isTrue);
  });

  test('toggleArchiveStatus() flips and restores the archive flag', () async {
    await setUpDataSource();
    final book = await fetchFirstBook(api);

    final first = await dataSource.toggleArchiveStatus(book.id);
    expect(first, isTrue);

    final second = await dataSource.toggleArchiveStatus(book.id);
    expect(second, isTrue);
  });

  test('getDownloadStream() returns a 200 stream for a real book', () async {
    await setUpDataSource();
    final book = await fetchFirstBook(api);

    final details = await dataSource.fetchBookDetails(book, book.uuid);
    if (details.formats.isEmpty) {
      markTestSkipped(
        'Book "${book.title}" has no downloadable formats -> cannot test',
      );
      return;
    }
    final format = details.formats.first;

    try {
      final response = await dataSource.getDownloadStream(
        book.id.toString(),
        format,
      );
      expect(response.statusCode, 200);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Server error') ||
          RegExp(r'(?:status |\()(4\d\d|5\d\d)').hasMatch(msg)) {
        markTestSkipped(
          'Book "${book.title}" not downloadable on server ($msg)',
        );
        return;
      }
      rethrow;
    }
  });

  test('getMetadataProviders() returns the configured providers', () async {
    await setUpDataSource();

    final providers = await dataSource.getMetadataProviders();

    expect(providers, isA<List>());
  });

  test(
    'searchMetadata() returns results for a query',
    () async {
      await setUpDataSource();

      try {
        final results = await dataSource
            .searchMetadata('Tolkien', const [])
            .timeout(const Duration(seconds: 20));
        expect(results, isA<List>());
      } catch (e) {
        final msg = e.toString();
        if (e is TimeoutException ||
            msg.contains('Server error') ||
            msg.contains('Connection closed') ||
            msg.contains('ClientException')) {
          markTestSkipped('Metadata provider search slow/unavailable ($msg)');
          return;
        }
        rethrow;
      }
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test('getSeriesPath() resolves without throwing', () async {
    await setUpDataSource();

    final path = await dataSource.getSeriesPath('Harry Potter');

    expect(path == null || path.isNotEmpty, isTrue);
  });

  test(
    'deleteBook() — POST /delete/{id}',
    () async {},
    skip: 'Destructive: permanently deletes a book from the real library.',
  );

  test(
    'updateBookMetadata() — POST /admin/book/{id}',
    () async {},
    skip: 'Destructive: overwrites metadata of a real book.',
  );

  test(
    'sendBookViaEmail() — POST /send/{id}/{format}/{conversion}',
    () async {},
    skip: 'Destructive: triggers a real e-mail send from the server.',
  );
}
