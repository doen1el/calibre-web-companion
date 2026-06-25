import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calibre_web_companion/core/services/digest_auth.dart';

String md5hex(String s) => md5.convert(utf8.encode(s)).toString();

String? field(String header, String key) {
  final m = RegExp('$key="([^"]*)"').firstMatch(header) ??
      RegExp('$key=([^,\\s]+)').firstMatch(header);
  return m?.group(1);
}

void main() {
  test('raw digest formula matches RFC 2617 example', () {
    final ha1 = md5hex('Mufasa:testrealm@host.com:Circle Of Life');
    final ha2 = md5hex('GET:/dir/index.html');
    final response = md5hex(
      '$ha1:dcd98b7102dd2f0e8b11d0f600bfb0c093:00000001:0a4f113b:auth:$ha2',
    );

    expect(ha1, '939e7578ed9e3c518a452acee763bce9');
    expect(ha2, '39aff3a2bab6126f332b942af96d3366');
    expect(response, '6629fae49393a05397450978507c4ef1');
  });

  test('buildAuthHeader produces a self-consistent qop=auth response', () {
    final digest = DigestAuth();
    final parsed = digest.parseChallenge(
      'Digest realm="calibre", nonce="abc123", algorithm="MD5", qop="auth"',
    );
    expect(parsed, isTrue);

    const user = 'alice';
    const pass = 's3cret';
    const uri = '/ajax/library-info';

    final header = digest.buildAuthHeader(
      method: 'GET',
      uri: uri,
      username: user,
      password: pass,
    )!;

    expect(field(header, 'username'), user);
    expect(field(header, 'realm'), 'calibre');
    expect(field(header, 'nonce'), 'abc123');
    expect(field(header, 'uri'), uri);
    expect(field(header, 'qop'), 'auth');
    expect(field(header, 'nc'), '00000001');

    final cnonce = field(header, 'cnonce')!;
    final ha1 = md5hex('$user:calibre:$pass');
    final ha2 = md5hex('GET:$uri');
    final expected = md5hex('$ha1:abc123:00000001:$cnonce:auth:$ha2');

    expect(field(header, 'response'), expected);
  });

  test('nonce-count increments across requests', () {
    final digest = DigestAuth();
    digest.parseChallenge('Digest realm="r", nonce="n", qop="auth"');

    final h1 = digest.buildAuthHeader(
      method: 'GET',
      uri: '/a',
      username: 'u',
      password: 'p',
    )!;
    final h2 = digest.buildAuthHeader(
      method: 'GET',
      uri: '/a',
      username: 'u',
      password: 'p',
    )!;

    expect(field(h1, 'nc'), '00000001');
    expect(field(h2, 'nc'), '00000002');
  });
}
