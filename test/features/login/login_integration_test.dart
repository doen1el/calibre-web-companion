@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';

import '../../helpers/test_setup.dart';

void main() {
  test('login() succeeds with valid credentials (POST /login)', () async {
    final api = await setupIntegrationTest();
    expect(api, isNotNull);
  });

  test('canAccessWebsite() returns true for a valid session', () async {
    final api = await setupIntegrationTest();
    final dataSource = LoginRemoteDataSource(
      apiService: api,
      logger: Logger(level: Level.off),
    );

    final canAccess = await dataSource.canAccessWebsite();
    expect(canAccess, isTrue);
  });

  test('getStoredServerType() reflects the stored server type', () async {
    final api = await setupIntegrationTest();
    final dataSource = LoginRemoteDataSource(
      apiService: api,
      logger: Logger(level: Level.off),
    );

    final type = await dataSource.getStoredServerType();
    expect(type.name, 'calibreWeb');
  });
}
