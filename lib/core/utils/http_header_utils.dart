import 'dart:convert';

/// Shared parsing, sanitizing and validation for user-configured HTTP headers.
///
/// Everything that reads the stored headers goes through here: a name or value
/// that survives storage has to be safe to hand to `HttpHeaders.set`, and a
/// pasted secret with a trailing newline must not silently break auth.
const String customHeadersPrefsKey = 'custom_login_headers';

const String cfAccessClientIdHeader = 'CF-Access-Client-Id';
const String cfAccessClientSecretHeader = 'CF-Access-Client-Secret';

/// RFC 9110 token characters — everything a header field name may contain.
final RegExp _headerNamePattern = RegExp(r"^[A-Za-z0-9!#$%&'*+\-.^_`|~]+$");

/// Control characters that would truncate or split the request line.
final RegExp _forbiddenInValue = RegExp(r'[\x00-\x08\x0a-\x1f\x7f]');

/// Control characters only — an inner space stays in the name so validation
/// rejects it instead of silently gluing "Bad Header" into "BadHeader".
final RegExp _forbiddenInName = RegExp(r'[\x00-\x1f\x7f]');

/// Header names that are only ever meaningful as one half of a pair, so seeing
/// one as a *value* means the user filled the form in wrong.
const Set<String> _knownHeaderNames = {
  'cf-access-client-id',
  'cf-access-client-secret',
  'authorization',
  'x-api-key',
  'x-auth-token',
  'x-auth-request-user',
  'cookie',
};

enum HeaderNameIssue { empty, invalidCharacters, duplicate }

enum HeaderValueIssue { empty, invalidCharacters, looksLikeHeaderName }

String sanitizeHeaderName(String value) =>
    value.replaceAll(_forbiddenInName, '').trim();

String sanitizeHeaderValue(String value) =>
    value.replaceAll(_forbiddenInValue, '').trim();

bool isValidHeaderName(String value) =>
    value.isNotEmpty && _headerNamePattern.hasMatch(value);

bool isValidHeaderValue(String value) => !_forbiddenInValue.hasMatch(value);

bool valueLooksLikeHeaderName(String value, String name) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  if (normalized == name.trim().toLowerCase()) return true;
  return _knownHeaderNames.contains(normalized);
}

bool isCloudflareAccessRedirect(String? location) =>
    location != null && location.contains('cdn-cgi/access');

/// Decodes the stored header list, dropping anything that cannot be sent.
Map<String, String> parseCustomHeaders(String rawJson, {String? username}) {
  final result = <String, String>{};

  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) return result;

    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      String? rawName;
      String? rawValue;
      if (map.containsKey('key') && map.containsKey('value')) {
        rawName = map['key']?.toString();
        rawValue = map['value']?.toString();
      } else if (map.isNotEmpty) {
        rawName = map.keys.first.toString();
        rawValue = map.values.first?.toString();
      }
      if (rawName == null || rawValue == null) continue;

      final name = sanitizeHeaderName(rawName);
      var value = sanitizeHeaderValue(rawValue);
      if (!isValidHeaderName(name) || value.isEmpty) continue;

      if (username != null && username.isNotEmpty) {
        value = value.replaceAll(r'${USERNAME}', username);
      }
      result[name] = value;
    }
  } catch (_) {
    // Malformed storage: keep whatever parsed cleanly.
  }

  return result;
}

/// Redacts a header value for diagnostics reports that get pasted into issues.
String maskHeaderValue(String value) {
  if (value.isEmpty) return '(empty)';
  final head =
      value.length <= 4 ? value.substring(0, 1) : value.substring(0, 4);
  // The ".access" suffix of a Cloudflare service-token client ID is public and
  // worth showing — a missing one is the most common misconfiguration.
  final suffix = value.endsWith('.access') ? '.access' : '';
  return '$head…$suffix (${value.length} chars)';
}

HeaderNameIssue? inspectHeaderName(String rawName, {bool isDuplicate = false}) {
  final name = sanitizeHeaderName(rawName);
  if (name.isEmpty) return HeaderNameIssue.empty;
  if (!isValidHeaderName(name)) return HeaderNameIssue.invalidCharacters;
  if (isDuplicate) return HeaderNameIssue.duplicate;
  return null;
}

HeaderValueIssue? inspectHeaderValue(String rawValue, {required String name}) {
  if (sanitizeHeaderValue(rawValue).isEmpty) return HeaderValueIssue.empty;
  if (!isValidHeaderValue(rawValue)) return HeaderValueIssue.invalidCharacters;
  if (valueLooksLikeHeaderName(rawValue, name)) {
    return HeaderValueIssue.looksLikeHeaderName;
  }
  return null;
}
