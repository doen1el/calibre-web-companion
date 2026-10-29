import 'dart:convert';

import 'package:calibre_web_companion/features/opds_browser/data/models/opds_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml2json/xml2json.dart';

const _feedUrl = 'https://books.example.org/opds/new';

// Trimmed from Calibre-Web, which labels book feeds kind=navigation too.
const _calibreWebFeed = '''
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:calibre="http://calibre.kovidgoyal.net/2009/metadata">
  <title>Calibre-Web - Recently added Books</title>
  <link rel="self" href="/opds/new?" type="application/atom+xml;profile=opds-catalog;type=feed;kind=navigation"/>
  <link rel="next" title="Next" href="/opds/new?offset=60" type="application/atom+xml;profile=opds-catalog;type=feed;kind=navigation"/>
  <link rel="search" href="/opds/osd" type="application/opensearchdescription+xml"/>
  <link type="application/atom+xml" rel="search" title="Search" href="/opds/search/{searchTerms}"/>
  <entry>
    <title>Authors</title>
    <link href="/opds/author" type="application/atom+xml;profile=opds-catalog"/>
    <id>/opds/author</id>
    <content type="text">Books ordered by Author</content>
  </entry>
  <entry>
    <title>Little Brother</title>
    <id>urn:uuid:7c9c66ce-9f71-46c2-85e9-154f18ef6cfa</id>
    <author><name>Cory Doctorow</name></author>
    <calibre:series>Little Brother</calibre:series>
    <calibre:series_index>1</calibre:series_index>
    <content type="text">Marcus is seventeen.</content>
    <link type="image/jpeg" href="/opds/cover/208" rel="http://opds-spec.org/image"/>
    <link rel="http://opds-spec.org/acquisition" href="/opds/download/208/epub/" type="application/epub+zip"/>
  </entry>
</feed>
''';

Map<String, dynamic> _parse(String xml) {
  final transformer = Xml2Json()..parse(xml);
  return jsonDecode(transformer.toParkerWithAttrs()) as Map<String, dynamic>;
}

void main() {
  final feed = OpdsFeed.fromJson(_parse(_calibreWebFeed), _feedUrl);

  test('classifies entries by acquisition link, not by feed kind', () {
    expect(feed.navigation.map((n) => n.title), ['Authors']);
    expect(feed.books.map((b) => b.title), ['Little Brother']);
  });

  test('resolves navigation, next, cover and download links', () {
    expect(feed.navigation.single.url, 'https://books.example.org/opds/author');
    expect(feed.navigation.single.subtitle, 'Books ordered by Author');
    expect(feed.nextUrl, 'https://books.example.org/opds/new?offset=60');

    final book = feed.books.single;
    expect(book.id, 208);
    expect(book.coverUrl, 'https://books.example.org/opds/cover/208');
    expect(book.downloadLinks, {
      'epub': 'https://books.example.org/opds/download/208/epub/',
    });
    expect(book.data, 'Marcus is seventeen.');
    expect(book.series, 'Little Brother');
    expect(book.seriesIndex, 1);
  });

  test('prefers the Atom search template over the OpenSearch description', () {
    expect(feed.searchIsTemplate, isTrue);
    expect(feed.searchHref, '/opds/search/{searchTerms}');
  });
}
