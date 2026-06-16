@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  test('GET /opds/shelf/{id} returns a parseable OPDS feed', () async {
    final api = await setupIntegrationTest();
    final logger = Logger(level: Level.off);

    final detailsSource = ShelfDetailsRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
    );
    final shelfViewSource = ShelfViewRemoteDataSource(
      apiService: api,
      logger: logger,
      preferences: testPrefs(),
      shelfDetailsRemoteDataSource: detailsSource,
    );
    final book = await fetchFirstBook(api);
    final shelfName = 'cwc_itest_${DateTime.now().millisecondsSinceEpoch}';

    String? shelfId;
    try {
      shelfId = await shelfViewSource.createShelf(shelfName);
      await shelfViewSource.addBookToShelf(
        bookId: book.id.toString(),
        shelfId: shelfId,
      );

      final response = await api.get(endpoint: '/opds/shelf/$shelfId');

      expect(response.statusCode, 200);
      expect(response.body, contains('<entry>'));

      final hasUuid = RegExp(
        r'<id>urn:uuid:([a-fA-F0-9-]+)</id>',
      ).hasMatch(response.body);
      final hasDownloadId = RegExp(
        r'href="\/opds\/download\/(\d+)\/',
      ).hasMatch(response.body);
      expect(hasUuid && hasDownloadId, isTrue);
    } finally {
      if (shelfId != null) {
        await detailsSource.deleteShelf(shelfId);
      }
    }
  });
}
