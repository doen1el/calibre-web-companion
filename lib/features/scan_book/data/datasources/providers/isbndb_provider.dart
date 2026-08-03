import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';

class IsbnDbProvider extends IsbnMetadataProvider {
  final String apiKey;

  IsbnDbProvider({required this.apiKey, super.client, super.logger});

  @override
  IsbnMetadataSource get source => IsbnMetadataSource.isbnDb;

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    if (apiKey.isEmpty) return null;

    final uri = Uri.parse('https://api2.isbndb.com/book/$isbn');
    final decoded = await fetchJson(uri, headers: {'Authorization': apiKey});
    if (decoded is! Map) return null;

    final entry = decoded['book'];
    if (entry is! Map) return null;

    final pages = entry['pages'];
    final book = IsbnBook(
      isbn: isbn,
      title: IsbnMetadataProvider.cleanText(
        entry['title_long'] ?? entry['title'],
      ),
      authors: IsbnMetadataProvider.stringList(entry['authors']),
      publisher: IsbnMetadataProvider.cleanText(entry['publisher']),
      publishDate: IsbnMetadataProvider.cleanText(entry['date_published']),
      coverUrl:
          IsbnMetadataProvider.cleanText(entry['image']).isEmpty
              ? null
              : IsbnMetadataProvider.cleanText(entry['image']),
      pageCount: pages is int ? pages : int.tryParse(pages?.toString() ?? ''),
      subjects:
          IsbnMetadataProvider.stringList(entry['subjects']).take(10).toList(),
      description: IsbnMetadataProvider.cleanText(
        entry['synopsis'] ?? entry['overview'],
      ),
      language: IsbnMetadataProvider.cleanText(entry['language']),
      sources: const [IsbnMetadataSource.isbnDb],
    );

    return book.hasUsableData ? book : null;
  }
}
