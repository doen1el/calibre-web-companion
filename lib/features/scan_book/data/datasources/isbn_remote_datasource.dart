import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';

class IsbnRemoteDataSource {
  final http.Client client;
  final Logger logger;

  IsbnRemoteDataSource({http.Client? client, Logger? logger})
    : client = client ?? http.Client(),
      logger = logger ?? Logger();

  static String normalizeIsbn(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

  Future<IsbnBook?> lookupByIsbn(String isbn) async {
    final normalized = normalizeIsbn(isbn);
    if (normalized.length != 10 && normalized.length != 13) {
      logger.w('Invalid ISBN length: $normalized');
      return null;
    }

    final uri = Uri.parse(
      'https://openlibrary.org/api/books'
      '?bibkeys=ISBN:$normalized&format=json&jscmd=data',
    );

    try {
      final response = await client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        logger.w('OpenLibrary lookup failed: ${response.statusCode}');
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map || decoded.isEmpty) {
        return null;
      }

      final entry = decoded['ISBN:$normalized'];
      if (entry is! Map<String, dynamic>) return null;

      return IsbnBook.fromOpenLibrary(normalized, entry);
    } catch (e) {
      logger.e('Error looking up ISBN $normalized: $e');
      throw Exception('ISBN lookup failed: $e');
    }
  }
}
