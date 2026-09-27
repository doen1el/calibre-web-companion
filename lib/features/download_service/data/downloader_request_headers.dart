import 'package:calibre_web_companion/core/utils/http_header_utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String downloaderUseSsoSessionKey = 'downloader_use_sso_session';

// Calibre-Web and Shelfmark are both Flask apps with the same cookie names, so
// forwarding Calibre-Web's session would clobber the downloader's own.
const Set<String> _calibreWebSessionCookies = {'session', 'remember_token'};

/// Opt-in because the stored SSO cookie header has lost its Domain attributes:
/// the app can't tell whether the proxy cookie is valid for the downloader host.
bool downloaderUsesSsoSession(SharedPreferences prefs) =>
    (prefs.getBool(downloaderUseSsoSessionKey) ?? false) &&
    (prefs.getBool('is_sso_session') ?? false);

String _ssoProxyCookies(SharedPreferences prefs) {
  final cookieHeader = prefs.getString('calibre_web_cookie') ?? '';
  return cookieHeader
      .split(';')
      .map((part) => part.trim())
      .where((kv) {
        final idx = kv.indexOf('=');
        if (idx <= 0) return false;
        final name = kv.substring(0, idx).trim().toLowerCase();
        return !_calibreWebSessionCookies.contains(name);
      })
      .join('; ');
}

/// Headers for every downloader request, cover images included.
Map<String, String> buildDownloaderHeaders(
  SharedPreferences prefs, {
  bool includeDownloaderCookie = true,
}) {
  final headers = parseCustomHeaders(
    prefs.getString(customHeadersPrefsKey) ?? '[]',
    username: prefs.getString('username'),
  );

  final customCookieKey = headers.keys.firstWhere(
    (k) => k.toLowerCase() == 'cookie',
    orElse: () => '',
  );
  var cookie = customCookieKey.isEmpty ? '' : headers.remove(customCookieKey)!;

  if (downloaderUsesSsoSession(prefs)) {
    cookie = mergeCookieHeaders(cookie, _ssoProxyCookies(prefs));
  }
  if (includeDownloaderCookie) {
    cookie = mergeCookieHeaders(
      cookie,
      prefs.getString('downloader_cookie') ?? '',
    );
  }
  if (cookie.isNotEmpty) headers['Cookie'] = cookie;

  return headers;
}

/// Forward-auth proxies answer an unauthenticated request with a 401, a
/// redirect to their portal (followed automatically for GET), or the portal's
/// HTML with a 200.
bool isInterceptedByAuthProxy(http.Response response) {
  final status = response.statusCode;
  if (status == 401 || (status >= 300 && status < 400)) return true;
  return looksLikeHtmlResponse(response);
}

bool looksLikeHtmlResponse(http.Response response) {
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  if (contentType.contains('text/html')) return true;
  final body = response.body.trimLeft();
  return body.startsWith('<');
}

class DownloaderLoginPageException implements Exception {
  const DownloaderLoginPageException();

  @override
  String toString() =>
      'The downloader returned a login page instead of data. Is an auth proxy '
      '(SSO) intercepting it? If you log in to Calibre-Web via SSO, enable '
      '"Use SSO session for downloader" in the downloader settings.';
}
