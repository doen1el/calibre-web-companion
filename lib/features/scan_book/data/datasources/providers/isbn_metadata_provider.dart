import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';

abstract class IsbnMetadataProvider {
  final http.Client client;
  final Logger logger;

  IsbnMetadataProvider({http.Client? client, Logger? logger})
    : client = client ?? http.Client(),
      logger = logger ?? Logger();

  static const Duration requestTimeout = Duration(seconds: 12);

  IsbnMetadataSource get source;

  Future<IsbnBook?> lookup(String isbn);

  Future<String?> fetchBody(Uri uri, {Map<String, String>? headers}) async {
    final response = await client
        .get(uri, headers: headers)
        .timeout(requestTimeout);

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('${source.label} returned ${response.statusCode}');
    }

    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<dynamic> fetchJson(Uri uri, {Map<String, String>? headers}) async {
    final body = await fetchBody(
      uri,
      headers: {'Accept': 'application/json', ...?headers},
    );
    if (body == null || body.isEmpty) return null;
    return json.decode(body);
  }

  static final HtmlUnescape _unescape = HtmlUnescape();

  static String cleanText(dynamic value) {
    if (value == null) return '';
    return _unescape
        .convert(value.toString().replaceAll(RegExp(r'<[^>]+>'), ' '))
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([,.])'), (m) => m[1]!)
        .trim();
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
