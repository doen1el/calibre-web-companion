import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';

class GoogleBooksProvider extends IsbnMetadataProvider {
  final String apiKey;

  GoogleBooksProvider({this.apiKey = '', super.client, super.logger});

  @override
  IsbnMetadataSource get source => IsbnMetadataSource.googleBooks;

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': 'isbn:$isbn',
      'maxResults': '1',
      if (apiKey.isNotEmpty) 'key': apiKey,
    });

    final decoded = await fetchJson(uri);
    if (decoded is! Map) return null;

    final items = decoded['items'];
    if (items is! List || items.isEmpty) return null;

    final info = items.first is Map ? items.first['volumeInfo'] : null;
    if (info is! Map) return null;

    final title = IsbnMetadataProvider.cleanText(info['title']);
    final subtitle = IsbnMetadataProvider.cleanText(info['subtitle']);

    final book = IsbnBook(
      isbn: isbn,
      title: subtitle.isEmpty ? title : '$title: $subtitle',
      authors: IsbnMetadataProvider.stringList(info['authors']),
      publisher: IsbnMetadataProvider.cleanText(info['publisher']),
      publishDate: IsbnMetadataProvider.cleanText(info['publishedDate']),
      coverUrl: _coverUrl(info['imageLinks']),
      pageCount: info['pageCount'] is int ? info['pageCount'] as int : null,
      subjects:
          IsbnMetadataProvider.stringList(info['categories']).take(10).toList(),
      description: IsbnMetadataProvider.cleanText(info['description']),
      language: IsbnMetadataProvider.cleanText(info['language']),
      sources: const [IsbnMetadataSource.googleBooks],
    );

    return book.hasUsableData ? book : null;
  }

  String? _coverUrl(dynamic imageLinks) {
    if (imageLinks is! Map) return null;
    final raw =
        imageLinks['extraLarge'] ??
        imageLinks['large'] ??
        imageLinks['medium'] ??
        imageLinks['thumbnail'] ??
        imageLinks['smallThumbnail'];
    if (raw == null) return null;

    return raw
        .toString()
        .replaceFirst('http://', 'https://')
        .replaceAll('&edge=curl', '');
  }
}
