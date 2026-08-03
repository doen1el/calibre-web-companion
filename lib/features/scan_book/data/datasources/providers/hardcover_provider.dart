import 'dart:convert';

import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_utils.dart';

class HardcoverProvider extends IsbnMetadataProvider {
  final String token;

  HardcoverProvider({required this.token, super.client, super.logger});

  static final Uri _endpoint = Uri.parse(
    'https://api.hardcover.app/v1/graphql',
  );

  static const String _fullQuery = r'''
query BookByIsbn($isbns: [String!]) {
  editions(where: {_or: [{isbn_13: {_in: $isbns}}, {isbn_10: {_in: $isbns}}]}, limit: 1) {
    title
    pages
    release_date
    cached_image
    publisher { name }
    language { code2 }
    contributions { author { name } }
    book { title description }
  }
}
''';

  static const String _minimalQuery = r'''
query BookByIsbn($isbns: [String!]) {
  editions(where: {isbn_13: {_in: $isbns}}, limit: 1) {
    title
    pages
    release_date
    book { title description }
  }
}
''';

  @override
  IsbnMetadataSource get source => IsbnMetadataSource.hardcover;

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    if (token.isEmpty) return null;

    final isbn13 = toIsbn13(isbn);
    final isbn10 = toIsbn10(isbn);
    final isbns =
        <String>{
          isbn,
          if (isbn13 != null) isbn13,
          if (isbn10 != null) isbn10,
        }.toList();

    var edition = await _query(_fullQuery, isbns);
    edition ??= await _query(_minimalQuery, isbns);
    if (edition == null) return null;

    final bookNode = edition['book'];
    final book = bookNode is Map ? bookNode : const {};

    final authors = <String>[];
    final contributions = edition['contributions'];
    if (contributions is List) {
      for (final contribution in contributions) {
        if (contribution is! Map) continue;
        final author = contribution['author'];
        final name =
            author is Map ? IsbnMetadataProvider.cleanText(author['name']) : '';
        if (name.isNotEmpty && !authors.contains(name)) authors.add(name);
      }
    }

    final publisher = edition['publisher'];
    final language = edition['language'];

    final result = IsbnBook(
      isbn: isbn,
      title: IsbnMetadataProvider.cleanText(edition['title'] ?? book['title']),
      authors: authors,
      publisher:
          publisher is Map
              ? IsbnMetadataProvider.cleanText(publisher['name'])
              : '',
      publishDate: IsbnMetadataProvider.cleanText(edition['release_date']),
      coverUrl: _imageUrl(edition['cached_image']),
      pageCount:
          edition['pages'] is int
              ? edition['pages'] as int
              : int.tryParse(edition['pages']?.toString() ?? ''),
      description: IsbnMetadataProvider.cleanText(book['description']),
      language:
          language is Map
              ? IsbnMetadataProvider.cleanText(language['code2'])
              : '',
      sources: const [IsbnMetadataSource.hardcover],
    );

    return result.hasUsableData ? result : null;
  }

  Future<Map<dynamic, dynamic>?> _query(
    String query,
    List<String> isbns,
  ) async {
    final response = await client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization':
                token.toLowerCase().startsWith('bearer ')
                    ? token
                    : 'Bearer $token',
          },
          body: json.encode({
            'query': query,
            'variables': {'isbns': isbns},
          }),
        )
        .timeout(IsbnMetadataProvider.requestTimeout);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Hardcover rejected the API token');
    }
    if (response.statusCode != 200) {
      throw Exception('Hardcover returned ${response.statusCode}');
    }

    final decoded = json.decode(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    if (decoded is! Map) return null;

    if (decoded['errors'] != null) {
      logger.w('Hardcover GraphQL error: ${decoded['errors']}');
      return null;
    }

    final editions = decoded['data']?['editions'];
    if (editions is! List || editions.isEmpty) return null;
    return editions.first is Map ? editions.first as Map : null;
  }

  String? _imageUrl(dynamic cachedImage) {
    dynamic value = cachedImage;
    if (value is String && value.startsWith('{')) {
      try {
        value = json.decode(value);
      } catch (_) {
        return null;
      }
    }
    if (value is Map) {
      final url = IsbnMetadataProvider.cleanText(value['url']);
      return url.isEmpty ? null : url;
    }
    return null;
  }
}
