import 'dart:convert';
import 'dart:io';

import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test('handles multiple WWW-Authenticate challenges (#213)', () async {
    final expected = 'Basic ${base64Encode(utf8.encode('u:p'))}';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      if (req.headers.value('authorization') != expected) {
        req.response.statusCode = 401;
        req.response.headers.noFolding('www-authenticate');
        req.response.headers.add('www-authenticate', 'Bearer realm="oc"');
        req.response.headers.add('www-authenticate', 'Basic realm="oc"');
      } else {
        req.response.statusCode = 207;
        req.response.headers.contentType = ContentType(
          'application',
          'xml',
          charset: 'utf-8',
        );
        req.response.write(
          '<?xml version="1.0"?><d:multistatus xmlns:d="DAV:"></d:multistatus>',
        );
      }
      await req.response.close();
    });

    final service = WebDavSyncService(logger: Logger())
      ..init('http://127.0.0.1:${server.port}/', 'u', 'p');
    await service.testConnection();
    await server.close(force: true);
  });
}
