@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/download_service/data/datasources/download_service_remote_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_local_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/repositories/login_settings_repository.dart';

import '../../test_env.dart';

void main() {
  late DownloadServiceRemoteDataSource dataSource;

  Future<void> setUpDataSource() async {
    SharedPreferences.setMockInitialValues({
      'downloader_url': TestEnv.downloaderUrl,
      'downloader_username': TestEnv.downloaderUsername,
      'downloader_password': TestEnv.downloaderPassword,
    });
    final prefs = await SharedPreferences.getInstance();
    final logger = Logger(level: Level.off);

    final loginSettingsRepository = LoginSettingsRepository(
      loginSettingsLocalDataSource: LoginSettingsLocalDataSource(
        preferences: prefs,
        logger: logger,
        apiService: ApiService(),
      ),
      logger: logger,
    );

    dataSource = DownloadServiceRemoteDataSource(
      client: http.Client(),
      sharedPreferences: prefs,
      logger: logger,
      loginSettingsRepository: loginSettingsRepository,
    );
  }

  test(
    'searchBooks() returns results (GET /api/releases)',
    () async {
      await setUpDataSource();

      final books = await dataSource.searchBooks('Tolkien');

      expect(books, isA<List>());
    },
    skip: TestEnv.hasDownloader ? false : 'TestEnv.downloaderUrl not set',
  );

  test(
    'getDownloadStatus() returns status (GET /api/status)',
    () async {
      await setUpDataSource();

      final books = await dataSource.getDownloadStatus();

      expect(books, isA<List>());
    },
    skip: TestEnv.hasDownloader ? false : 'TestEnv.downloaderUrl not set',
  );

  test(
    'getConfig() returns the downloader config (GET /api/config)',
    () async {
      await setUpDataSource();

      final config = await dataSource.getConfig();

      expect(config, isNotNull);
    },
    skip: TestEnv.hasDownloader ? false : 'TestEnv.downloaderUrl not set',
  );

  test(
    'downloadBook() — POST /api/releases/download',
    () async {},
    skip: 'Destructive: queues a real download on the downloader service.',
  );
}
