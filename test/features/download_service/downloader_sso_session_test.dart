import 'dart:convert';

import 'package:calibre_web_companion/core/services/session_reauth_service.dart';
import 'package:calibre_web_companion/features/download_service/data/datasources/download_service_remote_datasource.dart';
import 'package:calibre_web_companion/features/download_service/data/downloader_request_headers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ssoCookie = 'authelia_session=proxy123; session=cw456';
const _loginPage = '<!--\n<html><body>Authelia login</body></html>';

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues({
    'downloader_url': 'https://dl.example.com',
    ...values,
  });
  return SharedPreferences.getInstance();
}

void main() {
  tearDown(() => SessionReauthService().registerHandler(null));

  group('buildDownloaderHeaders', () {
    test('ignores the SSO cookie while the toggle is off', () async {
      final prefs = await _prefs({
        'is_sso_session': true,
        'calibre_web_cookie': _ssoCookie,
        'downloader_cookie': 'session=dl789',
      });

      expect(buildDownloaderHeaders(prefs)['Cookie'], 'session=dl789');
    });

    test('forwards proxy cookies but not the Calibre-Web session', () async {
      final prefs = await _prefs({
        'is_sso_session': true,
        downloaderUseSsoSessionKey: true,
        'calibre_web_cookie': '$_ssoCookie; remember_token=rt',
        'downloader_cookie': 'session=dl789',
      });

      expect(
        buildDownloaderHeaders(prefs)['Cookie'],
        'authelia_session=proxy123; session=dl789',
      );
      expect(
        buildDownloaderHeaders(prefs, includeDownloaderCookie: false)['Cookie'],
        'authelia_session=proxy123',
      );
    });

    test('requires an actual SSO login, not just the toggle', () async {
      final prefs = await _prefs({
        downloaderUseSsoSessionKey: true,
        'calibre_web_cookie': _ssoCookie,
      });

      expect(buildDownloaderHeaders(prefs).containsKey('Cookie'), isFalse);
    });

    test(
      'merges with a custom Cookie header and keeps other headers',
      () async {
        final prefs = await _prefs({
          'is_sso_session': true,
          downloaderUseSsoSessionKey: true,
          'calibre_web_cookie': _ssoCookie,
          'custom_login_headers': jsonEncode([
            {'key': 'cookie', 'value': 'extra=1'},
            {'key': 'CF-Access-Client-Id', 'value': 'id.access'},
          ]),
        });

        final headers = buildDownloaderHeaders(prefs);
        expect(headers['Cookie'], 'extra=1; authelia_session=proxy123');
        expect(headers['CF-Access-Client-Id'], 'id.access');
        expect(headers.containsKey('cookie'), isFalse);
      },
    );

    // #204: covers use these headers too, so a header-authenticating proxy
    // must see the custom headers without the SSO toggle.
    test('sends custom headers alongside the downloader cookie', () async {
      final prefs = await _prefs({
        'downloader_cookie': 'session=dl789',
        'custom_login_headers': jsonEncode([
          {'key': 'Proxy-Authorization', 'value': 'Basic abc'},
        ]),
      });

      expect(buildDownloaderHeaders(prefs), {
        'Proxy-Authorization': 'Basic abc',
        'Cookie': 'session=dl789',
      });
    });
  });

  group('DownloadServiceRemoteDataSource', () {
    DownloadServiceRemoteDataSource dataSource(
      SharedPreferences prefs,
      MockClient client,
    ) => DownloadServiceRemoteDataSource(
      client: client,
      sharedPreferences: prefs,
      logger: Logger(level: Level.off),
    );

    test('reports a login page instead of a JSON FormatException', () async {
      final prefs = await _prefs({});
      final client = MockClient(
        (_) async => http.Response(
          _loginPage,
          200,
          headers: {'content-type': 'text/html'},
        ),
      );

      expect(
        dataSource(prefs, client).getDownloadStatus(),
        throwsA(isA<DownloaderLoginPageException>()),
      );
    });

    test('re-authenticates via SSO and retries with the new cookie', () async {
      final prefs = await _prefs({
        'is_sso_session': true,
        downloaderUseSsoSessionKey: true,
        'calibre_web_cookie': 'authelia_session=expired',
      });
      var reauthCalls = 0;
      SessionReauthService().registerHandler(() async {
        reauthCalls++;
        await prefs.setString('calibre_web_cookie', 'authelia_session=fresh');
        return true;
      });

      final seenCookies = <String?>[];
      final client = MockClient((request) async {
        seenCookies.add(request.headers['Cookie']);
        if (request.headers['Cookie'] == 'authelia_session=fresh') {
          return http.Response('{}', 200);
        }
        return http.Response(_loginPage, 200);
      });

      await dataSource(prefs, client).getDownloadStatus();

      expect(reauthCalls, 1);
      expect(seenCookies, [
        'authelia_session=expired',
        'authelia_session=fresh',
      ]);
    });

    test(
      'a proxy 401 without downloader credentials opens SSO re-auth',
      () async {
        final prefs = await _prefs({
          'is_sso_session': true,
          downloaderUseSsoSessionKey: true,
          'calibre_web_cookie': 'authelia_session=expired',
        });
        var reauthCalls = 0;
        SessionReauthService().registerHandler(() async {
          reauthCalls++;
          await prefs.setString('calibre_web_cookie', 'authelia_session=fresh');
          return true;
        });

        final client = MockClient((request) async {
          if (request.headers['Cookie'] == 'authelia_session=fresh') {
            return http.Response('{}', 200);
          }
          return http.Response('', 401);
        });

        await dataSource(prefs, client).getDownloadStatus();
        expect(reauthCalls, 1);
      },
    );

    test('does not open SSO re-auth while the toggle is off', () async {
      final prefs = await _prefs({
        'is_sso_session': true,
        'calibre_web_cookie': _ssoCookie,
      });
      var reauthCalls = 0;
      SessionReauthService().registerHandler(() async {
        reauthCalls++;
        return true;
      });
      final client = MockClient((_) async => http.Response(_loginPage, 200));

      await expectLater(
        dataSource(prefs, client).getDownloadStatus(),
        throwsA(isA<DownloaderLoginPageException>()),
      );
      expect(reauthCalls, 0);
    });
  });
}
