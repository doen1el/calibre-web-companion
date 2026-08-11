import 'dart:convert';

import 'package:calibre_web_companion/core/utils/http_header_utils.dart';
import 'package:flutter_test/flutter_test.dart';

String _store(List<Map<String, String>> headers) => jsonEncode(headers);

void main() {
  group('parseCustomHeaders', () {
    test('trims whitespace and strips line breaks from pasted secrets', () {
      final headers = parseCustomHeaders(
        _store([
          {'key': ' CF-Access-Client-Id ', 'value': 'abc.access\n'},
          {'key': 'CF-Access-Client-Secret', 'value': '  s3cret  '},
        ]),
      );

      expect(headers, {
        'CF-Access-Client-Id': 'abc.access',
        'CF-Access-Client-Secret': 's3cret',
      });
    });

    test('drops entries that could not be sent', () {
      final headers = parseCustomHeaders(
        _store([
          {'key': 'Bad Header', 'value': 'x'},
          {'key': 'X-Empty', 'value': '   '},
          {'key': '', 'value': 'x'},
          {'key': 'X-Good', 'value': 'x'},
        ]),
      );

      expect(headers, {'X-Good': 'x'});
    });

    test('substitutes the username placeholder', () {
      final headers = parseCustomHeaders(
        _store([
          {'key': 'Remote-User', 'value': r'${USERNAME}'},
        ]),
        username: 'daniel',
      );

      expect(headers, {'Remote-User': 'daniel'});
    });

    test('returns empty on malformed storage instead of throwing', () {
      expect(parseCustomHeaders('not json'), isEmpty);
      expect(parseCustomHeaders('{}'), isEmpty);
    });
  });

  group('validation', () {
    test('flags a value that is really a header name', () {
      expect(
        inspectHeaderValue(
          'CF-Access-Client-Secret',
          name: 'CF-Access-Client-Id',
        ),
        HeaderValueIssue.looksLikeHeaderName,
      );
      expect(
        inspectHeaderValue('a1b2c3.access', name: 'CF-Access-Client-Id'),
        isNull,
      );
    });

    test('flags header names that are not RFC tokens', () {
      expect(inspectHeaderName('X Api Key'), HeaderNameIssue.invalidCharacters);
      expect(inspectHeaderName('X-Api-Key'), isNull);
      expect(
        inspectHeaderName('X-Api-Key', isDuplicate: true),
        HeaderNameIssue.duplicate,
      );
    });
  });

  group('maskHeaderValue', () {
    test('keeps the public .access suffix but redacts the rest', () {
      expect(maskHeaderValue('a1b2c3d4e5.access'), 'a1b2….access (17 chars)');
    });

    test('never reveals the tail of a secret', () {
      final masked = maskHeaderValue('supersecretvalue');
      expect(masked, isNot(contains('secretvalue')));
      expect(masked, startsWith('supe'));
    });
  });

  group('isCloudflareAccessRedirect', () {
    test('detects the Access login redirect', () {
      expect(
        isCloudflareAccessRedirect(
          'https://example.cloudflareaccess.com/cdn-cgi/access/login/books.example.com?kid=x',
        ),
        isTrue,
      );
      expect(isCloudflareAccessRedirect('https://example.com/login'), isFalse);
      expect(isCloudflareAccessRedirect(null), isFalse);
    });
  });
}
