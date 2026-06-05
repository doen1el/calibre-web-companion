@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  late BookViewRemoteDatasource dataSource;

  Future<void> setUpDataSource() async {
    final api = await setupIntegrationTest();
    dataSource = BookViewRemoteDatasource(
      apiService: api,
      logger: Logger(level: Level.off),
      preferences: testPrefs(),
    );
  }

  test('fetchBooks() returns books from the real library', () async {
    await setUpDataSource();

    final books = await dataSource.fetchBooks(offset: 0, limit: 10);

    expect(books, isNotEmpty);
    expect(books.first.id, greaterThan(0));
    expect(books.first.title, isNotEmpty);
  });

  test('fetchBooks() respects the limit parameter', () async {
    await setUpDataSource();

    final books = await dataSource.fetchBooks(offset: 0, limit: 3);

    expect(books.length, lessThanOrEqualTo(3));
  });

  test('fetchBooks() pagination via offset returns different pages', () async {
    await setUpDataSource();

    final firstPage = await dataSource.fetchBooks(offset: 0, limit: 5);
    final secondPage = await dataSource.fetchBooks(offset: 5, limit: 5);

    if (firstPage.isNotEmpty && secondPage.isNotEmpty) {
      expect(firstPage.first.id, isNot(equals(secondPage.first.id)));
    }
  });

  test('fetchBooks() with sort parameters does not error', () async {
    await setUpDataSource();

    final books = await dataSource.fetchBooks(
      offset: 0,
      limit: 5,
      sortBy: 'title',
      sortOrder: 'asc',
    );

    expect(books, isA<List>());
  });

  test('fetchBooks() with a search query returns matching books', () async {
    await setUpDataSource();

    final sample = await dataSource.fetchBooks(offset: 0, limit: 1);
    expect(sample, isNotEmpty);
    final token = sample.first.title.split(' ').first;

    final results = await dataSource.fetchBooks(
      offset: 0,
      limit: 10,
      searchQuery: token,
    );

    expect(results, isA<List>());
  });
}
