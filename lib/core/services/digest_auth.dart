import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class DigestAuth {
  String? _realm;
  String? _nonce;
  String? _qop;
  String? _opaque;
  String _algorithm = 'MD5';
  int _nc = 0;

  final Random _random = Random.secure();

  bool get hasChallenge => _nonce != null && _realm != null;

  bool parseChallenge(String? wwwAuthenticate) {
    if (wwwAuthenticate == null) return false;

    final lower = wwwAuthenticate.toLowerCase();
    final digestIndex = lower.indexOf('digest');
    if (digestIndex < 0) return false;

    final params = wwwAuthenticate.substring(digestIndex + 'digest'.length);

    String? read(String key) {
      final match = RegExp(
        '$key\\s*=\\s*(?:"([^"]*)"|([^,\\s]+))',
        caseSensitive: false,
      ).firstMatch(params);
      return match?.group(1) ?? match?.group(2);
    }

    final nonce = read('nonce');
    if (nonce == null) return false;

    _realm = read('realm') ?? _realm ?? '';
    _nonce = nonce;
    _qop = read('qop');
    _opaque = read('opaque');
    _algorithm = read('algorithm') ?? 'MD5';
    _nc = 0;
    return true;
  }

  String? buildAuthHeader({
    required String method,
    required String uri,
    required String username,
    required String password,
  }) {
    if (_nonce == null || _realm == null) return null;

    _nc++;
    final ncHex = _nc.toRadixString(16).padLeft(8, '0');
    final cnonce = _generateCnonce();
    final qop = _selectQop(_qop);

    final ha1 = _md5('$username:$_realm:$password');
    final ha2 = _md5('$method:$uri');

    final String response;
    if (qop != null) {
      response = _md5('$ha1:$_nonce:$ncHex:$cnonce:$qop:$ha2');
    } else {
      response = _md5('$ha1:$_nonce:$ha2');
    }

    final buffer = StringBuffer('Digest ');
    buffer.write('username="$username", ');
    buffer.write('realm="$_realm", ');
    buffer.write('nonce="$_nonce", ');
    buffer.write('uri="$uri", ');
    buffer.write('algorithm=$_algorithm, ');
    buffer.write('response="$response"');
    if (qop != null) {
      buffer.write(', qop=$qop, nc=$ncHex, cnonce="$cnonce"');
    }
    if (_opaque != null) {
      buffer.write(', opaque="$_opaque"');
    }
    return buffer.toString();
  }

  void reset() {
    _realm = null;
    _nonce = null;
    _qop = null;
    _opaque = null;
    _algorithm = 'MD5';
    _nc = 0;
  }

  String? _selectQop(String? qop) {
    if (qop == null || qop.isEmpty) return null;
    final options = qop.split(',').map((e) => e.trim().toLowerCase());
    if (options.contains('auth')) return 'auth';
    return options.first;
  }

  String _md5(String input) => md5.convert(utf8.encode(input)).toString();

  String _generateCnonce() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
