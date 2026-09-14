import 'dart:io';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _loginPage =
    '<!DOCTYPE html><html><body>'
    '<div class="flash_success">You are now logged in as: user</div>'
    '<form><input name="csrf_token" value="token">'
    '<input name="username"><input name="password"></form>'
    '</body></html>';

const _epubBytes = [0x50, 0x4B, 0x03, 0x04];

/// Mimics Calibre-Web: downloads without a valid session are redirected to the
/// login page. [acceptLogin] controls whether a re-login yields such a session.
Future<HttpServer> _startServer({required bool acceptLogin}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response;
    final hasSession =
        request.headers.value('cookie')?.contains('session=fresh') ?? false;

    if (request.uri.path == '/login' && request.method == 'GET') {
      response.headers.contentType = ContentType.html;
      response.write(_loginPage);
    } else if (request.uri.path == '/login') {
      await request.drain<void>();
      response.statusCode = HttpStatus.found;
      response.headers.set('location', '/');
      if (acceptLogin) {
        response.headers.set('set-cookie', 'session=fresh; Path=/');
      }
    } else if (request.uri.path.startsWith('/download/') && hasSession) {
      response.headers.contentType = ContentType('application', 'epub+zip');
      response.add(_epubBytes);
    } else {
      response.statusCode = HttpStatus.found;
      response.headers.set('location', '/login?next=${request.uri.path}');
    }
    await response.close();
  });
  return server;
}

Future<ApiService> _apiServiceFor(HttpServer server) async {
  SharedPreferences.setMockInitialValues({
    'base_url': 'http://127.0.0.1:${server.port}',
    'username': 'user',
    'password': 'secret',
    'calibre_web_cookie': 'session=stale',
  });
  final apiService = ApiService();
  await apiService.initialize();
  return apiService;
}

void main() {
  test('re-authenticates when a download returns the login page', () async {
    final server = await _startServer(acceptLogin: true);
    addTearDown(() => server.close(force: true));
    final apiService = await _apiServiceFor(server);

    final response = await apiService.getStream(
      endpoint: '/download/1/epub/1.epub',
      authMethod: AuthMethod.cookie,
      expectFile: true,
    );

    expect(await response.stream.toBytes(), _epubBytes);
  });

  test('throws instead of returning the login page as the file', () async {
    final server = await _startServer(acceptLogin: false);
    addTearDown(() => server.close(force: true));
    final apiService = await _apiServiceFor(server);

    await expectLater(
      apiService.getStream(
        endpoint: '/download/1/epub/1.epub',
        authMethod: AuthMethod.cookie,
        expectFile: true,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('login page'),
        ),
      ),
    );
  });
}
