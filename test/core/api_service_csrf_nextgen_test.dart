import 'dart:convert';
import 'dart:io';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _spaShell =
    '<!DOCTYPE html><html><body><div id="app"></div></body></html>';

const _classicLogin =
    '<!DOCTYPE html><html><body><form>'
    '<input type="hidden" name="csrf_token" value="classic-token">'
    '<input name="username"><input name="password"></form>'
    '</body></html>';

bool _isDocumentNavigation(HttpRequest request) {
  final accept = request.headers.value('accept') ?? '';
  final dest = request.headers.value('sec-fetch-dest');
  final mode = request.headers.value('sec-fetch-mode');
  return accept.contains('text/html') &&
      (dest == null || dest == 'document') &&
      (mode == null || mode == 'navigate');
}

/// Mimics Calibre-Web-NextGen: browser navigations of `/login` and `/` are
/// redirected to the SPA shell. With [alwaysSpa] the classic page is never
/// served, leaving only the JSON CSRF endpoint.
Future<HttpServer> _startServer({
  required bool alwaysSpa,
  required List<String> postedTokens,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response;
    final path = request.uri.path;

    if (request.method == 'POST' && path == '/login') {
      final body = await utf8.decoder.bind(request).join();
      postedTokens.add(Uri.splitQueryString(body)['csrf_token'] ?? '');
      response.statusCode = HttpStatus.found;
      response.headers.set('location', '/');
      response.headers.set('set-cookie', 'session=fresh; Path=/');
    } else if (path == '/api/v1/auth/csrf') {
      response.headers.contentType = ContentType.json;
      response.write('{"csrf_token": "api-token"}');
    } else if (path == '/app/') {
      response.headers.contentType = ContentType.html;
      response.write(_spaShell);
    } else if ((path == '/login' || path == '/') &&
        (alwaysSpa || _isDocumentNavigation(request))) {
      response.statusCode = HttpStatus.found;
      response.headers.set('location', '/app/');
    } else if (path == '/login') {
      response.headers.contentType = ContentType.html;
      response.write(_classicLogin);
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  });
  return server;
}

Future<ApiService> _apiServiceFor(HttpServer server) async {
  SharedPreferences.setMockInitialValues({
    'base_url': 'http://127.0.0.1:${server.port}',
  });
  final apiService = ApiService();
  await apiService.initialize();
  return apiService;
}

Future<void> _login(ApiService apiService) => apiService.post(
  endpoint: '/login',
  body: {'username': 'user', 'password': 'secret'},
  authMethod: AuthMethod.none,
  contentType: 'application/x-www-form-urlencoded',
  useCsrf: true,
);

void main() {
  test('fetches the token from the classic login page', () async {
    final posted = <String>[];
    final server = await _startServer(alwaysSpa: false, postedTokens: posted);
    addTearDown(() => server.close(force: true));

    await _login(await _apiServiceFor(server));

    expect(posted, ['classic-token']);
  });

  test('falls back to the JSON CSRF endpoint', () async {
    final posted = <String>[];
    final server = await _startServer(alwaysSpa: true, postedTokens: posted);
    addTearDown(() => server.close(force: true));

    await _login(await _apiServiceFor(server));

    expect(posted, ['api-token']);
  });
}
