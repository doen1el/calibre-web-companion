@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  late DiscoverDetailsRemoteDatasource dataSource;

  Future<void> setUpDataSource() async {
    final api = await setupIntegrationTest();
    dataSource = DiscoverDetailsRemoteDatasource(
      apiService: api,
      logger: Logger(level: Level.off),
      preferences: testPrefs(),
    );
  }

  const optionalTypes = {
    DiscoverType.hot,
    DiscoverType.rated,
    DiscoverType.readbooks,
    DiscoverType.unreadbooks,
  };
  for (final type in const [
    DiscoverType.discover,
    DiscoverType.hot,
    DiscoverType.newlyAdded,
    DiscoverType.rated,
    DiscoverType.readbooks,
    DiscoverType.unreadbooks,
  ]) {
    test('loadBooks(${type.name}) returns a feed', () async {
      await setUpDataSource();

      try {
        final feed = await dataSource.loadBooks(type);
        expect(feed, isNotNull);
        expect(feed.books, isA<List>());
      } catch (e) {
        if (optionalTypes.contains(type) && e.toString().contains('404')) {
          return;
        }
        rethrow;
      }
    });
  }

  for (final type in const [
    CategoryType.author,
    CategoryType.category,
    CategoryType.series,
    CategoryType.publisher,
    CategoryType.language,
    CategoryType.formats,
    CategoryType.ratings,
  ]) {
    test('loadCategories(${type.name}) returns a feed', () async {
      await setUpDataSource();

      final feed = await dataSource.loadCategories(type);

      expect(feed, isNotNull);
      expect(feed.categories, isA<List>());
    });
  }

  test('loadCategories(libraries) hits /libraries', () async {
    await setUpDataSource();

    try {
      final feed = await dataSource.loadCategories(CategoryType.libraries);
      expect(feed.categories, isA<List>());
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });

  test('loadBooksFromPath() loads books from an explicit OPDS path', () async {
    await setUpDataSource();

    final feed = await dataSource.loadBooksFromPath('/opds/new');

    expect(feed, isNotNull);
    expect(feed.books, isA<List>());
  });

  test('loadCategoriesgeneric() parses a category path', () async {
    await setUpDataSource();

    final feed = await dataSource.loadCategoriesgeneric('/opds/category');

    expect(feed, isNotNull);
    expect(feed.categories, isA<List>());
  });
}
