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
  late ShelfDetailsRemoteDataSource dataSource;
  late ShelfViewRemoteDataSource shelfViewSource;

  Future<void> setUpDataSources() async {
    api = await setupIntegrationTest();
    logger = Logger(level: Level.off);
    dataSource = ShelfDetailsRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
    );
    shelfViewSource = ShelfViewRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
      shelfDetailsRemoteDataSource: dataSource,
    );
  }

  test('getShelfDetails() loads a freshly created shelf', () async {
    await setUpDataSources();
    final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

    String? shelfId;
    try {
      shelfId = await shelfViewSource.createShelf(shelfName);

      // GET /opds/shelf/{id}
      final details = await dataSource.getShelfDetails(shelfId);
      expect(details, isNotNull);
      expect(details.books, isA<List>());
    } finally {
      if (shelfId != null) {
        await dataSource.deleteShelf(shelfId);
      }
    }
  });

  test('editShelf() renames a shelf (POST /shelf/edit/{id})', () async {
    await setUpDataSources();
    final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

    String? shelfId;
    try {
      shelfId = await shelfViewSource.createShelf(shelfName);

      final renamed = await dataSource.editShelf(
        shelfId,
        '${shelfName}_edited',
      );
      expect(renamed, isTrue);
    } finally {
      if (shelfId != null) {
        await dataSource.deleteShelf(shelfId);
      }
    }
  });

  test('removeFromShelf() removes a book (POST /shelf/remove)', () async {
    await setUpDataSources();
    final book = await fetchFirstBook(api);
    final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

    String? shelfId;
    try {
      shelfId = await shelfViewSource.createShelf(shelfName);
      await shelfViewSource.addBookToShelf(
        bookId: book.id.toString(),
        shelfId: shelfId,
      );

      final removed = await dataSource.removeFromShelf(
        shelfId,
        book.id.toString(),
      );
      expect(removed, isTrue);
    } finally {
      if (shelfId != null) {
        await dataSource.deleteShelf(shelfId);
      }
    }
  });

  test('deleteShelf() deletes a shelf (POST /shelf/delete/{id})', () async {
    await setUpDataSources();
    final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

    final shelfId = await shelfViewSource.createShelf(shelfName);
    final deleted = await dataSource.deleteShelf(shelfId);

    expect(deleted, isTrue);
  });
}
