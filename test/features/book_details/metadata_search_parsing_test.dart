import 'dart:convert';

import 'package:calibre_web_companion/features/book_details/data/models/metadata_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _record = {
  'id': 'abc',
  'title': 'Dune',
  'authors': ['Frank Herbert'],
  'url': 'https://example.org/dune',
  'source': {
    'id': 'google',
    'description': 'Google',
    'link': 'https://books.google.com/',
  },
  'cover': 'https://example.org/dune.jpg',
  'description': null,
  'series': null,
  'series_index': 1,
  'identifiers': {'isbn': '9780441013593'},
  'publisher': null,
  'publishedDate': '1965-08-01',
  'rating': 4,
  'languages': ['en'],
  'tags': ['Science Fiction'],
};

void main() {
  test('parses the bare list returned by Calibre-Web', () {
    final response = MetadataSearchResponse.fromDecoded(
      jsonDecode(jsonEncode([_record])),
    );
    final results = response.results;
    expect(response.providers, isEmpty);

    expect(results, hasLength(1));
    expect(results.single.title, 'Dune');
    expect(results.single.authors, 'Frank Herbert');
    expect(results.single.sourceId, 'google');
  });

  test('parses the wrapped object returned by Calibre-Web-NextGen (#221)', () {
    final response = MetadataSearchResponse.fromDecoded(
      jsonDecode(
        jsonEncode({
          'results': [_record],
          'providers': [
            {'id': 'google', 'name': 'Google', 'status': 'ok', 'count': 1},
            {'id': 'amazon', 'name': 'Amazon', 'status': 'empty', 'count': 0},
            {'id': 'comicvine', 'name': 'ComicVine', 'status': 'disabled'},
            {
              'id': 'isbndb',
              'name': 'ISBNdb',
              'status': 'missing_key',
              'message': 'Add an API key',
            },
            {'id': 'goodreads', 'name': 'Goodreads', 'status': 'rate_limited'},
            {'id': 'x', 'name': 'X', 'status': 'something_new'},
          ],
        }),
      ),
    );
    final results = response.results;

    expect(response.providers, hasLength(6));
    expect(response.problems.map((p) => p.state), [
      MetadataProviderState.missingKey,
      MetadataProviderState.rateLimited,
      MetadataProviderState.error,
    ]);
    expect(response.problems.first.message, 'Add an API key');

    expect(results, hasLength(1));
    expect(results.single.title, 'Dune');
    expect(results.single.description, '');
    expect(results.single.publisher, '');
  });

  test('returns empty for unexpected shapes', () {
    expect(
      MetadataSearchResponse.fromDecoded(const {'providers': []}).results,
      isEmpty,
    );
    expect(MetadataSearchResponse.fromDecoded('nope').results, isEmpty);
  });
}
