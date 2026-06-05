@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:calibre_web_companion/features/me/data/datasources/me_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  test('getStats() returns library statistics', () async {
    final api = await setupIntegrationTest();
    final dataSource = MeRemoteDataSource(
      apiService: api,
      preferences: testPrefs(),
    );

    final stats = await dataSource.getStats();

    expect(stats, isNotNull);
    expect(stats.books, greaterThanOrEqualTo(0));
  });

  test('getIsOpds() is false for a Calibre-Web server', () async {
    final api = await setupIntegrationTest();
    final dataSource = MeRemoteDataSource(
      apiService: api,
      preferences: testPrefs(),
    );

    expect(dataSource.getIsOpds(), isFalse);
  });

  test(
    'logOut() — GET /logout',
    () async {},
    skip: 'Skipped: ends the session shared by all integration tests.',
  );
}
