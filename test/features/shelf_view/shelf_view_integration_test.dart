@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  late ApiService api;
  late Logger logger;
  late ShelfDetailsRemoteDataSource detailsSource;
  late ShelfViewRemoteDataSource dataSource;

  Future<void> setUpDataSources() async {
    api = await setupIntegrationTest();
    logger = Logger(level: Level.off);
    detailsSource = ShelfDetailsRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
    );
    dataSource = ShelfViewRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
      shelfDetailsRemoteDataSource: detailsSource,
    );
  }

  test('loadShelves() returns the shelf list', () async {
    await setUpDataSources();

    final shelves = await dataSource.loadShelves();

    expect(shelves, isNotNull);
    expect(shelves.shelves, isA<List>());
  });

  test(
    'shelf lifecycle: create -> add book -> remove book -> delete',
    () async {
      await setUpDataSources();
      final book = await fetchFirstBook(api);
      final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

      String? shelfId;
      try {
        // POST /shelf/create
        shelfId = await dataSource.createShelf(shelfName);
        expect(shelfId, isNotEmpty);

        // POST /shelf/add/{shelf}/{book}
        await dataSource.addBookToShelf(
          bookId: book.id.toString(),
          shelfId: shelfId,
        );

        // POST /shelf/remove/{shelf}/{book}
        await dataSource.removeBookFromShelf(
          bookId: book.id.toString(),
          shelfId: shelfId,
        );
      } finally {
        if (shelfId != null) {
          await detailsSource.deleteShelf(shelfId);
        }
      }
    },
  );

  test('findShelvesContainingBook() runs without error', () async {
    await setUpDataSources();
    final book = await fetchFirstBook(api);

    final shelves = await dataSource.findShelvesContainingBook(
      book.id.toString(),
    );

    expect(shelves, isA<List>());
  });
}
