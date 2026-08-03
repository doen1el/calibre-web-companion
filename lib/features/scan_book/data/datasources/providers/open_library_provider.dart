import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';

class OpenLibraryProvider extends IsbnMetadataProvider {
  OpenLibraryProvider({super.client, super.logger});

  @override
  IsbnMetadataSource get source => IsbnMetadataSource.openLibrary;

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    return await _lookupBooksApi(isbn) ?? await _lookupSearchApi(isbn);
  }

  Future<IsbnBook?> _lookupBooksApi(String isbn) async {
    final uri = Uri.parse(
      'https://openlibrary.org/api/books'
      '?bibkeys=ISBN:$isbn&format=json&jscmd=data',
    );

    final decoded = await fetchJson(uri);
    if (decoded is! Map || decoded.isEmpty) return null;

    final entry = decoded['ISBN:$isbn'];
    if (entry is! Map<String, dynamic>) return null;

    final book = IsbnBook.fromOpenLibrary(isbn, entry);
    return book.hasUsableData ? book : null;
  }

  Future<IsbnBook?> _lookupSearchApi(String isbn) async {
    final uri = Uri.parse(
      'https://openlibrary.org/search.json'
      '?isbn=$isbn&limit=1'
      '&fields=title,author_name,publisher,publish_date,first_publish_year,'
      'cover_i,number_of_pages_median,subject,language',
    );

    final decoded = await fetchJson(uri);
    if (decoded is! Map) return null;

    final docs = decoded['docs'];
    if (docs is! List || docs.isEmpty) return null;
    final doc = docs.first;
    if (doc is! Map) return null;

    final coverId = doc['cover_i'];
    final languages = IsbnMetadataProvider.stringList(doc['language']);

    final book = IsbnBook(
      isbn: isbn,
      title: IsbnMetadataProvider.cleanText(doc['title']),
      authors: IsbnMetadataProvider.stringList(doc['author_name']),
      publisher:
          IsbnMetadataProvider.stringList(doc['publisher']).take(1).join(),
      publishDate: IsbnMetadataProvider.cleanText(doc['first_publish_year']),
      coverUrl:
          coverId is int
              ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
              : null,
      pageCount:
          doc['number_of_pages_median'] is int
              ? doc['number_of_pages_median'] as int
              : null,
      subjects:
          IsbnMetadataProvider.stringList(doc['subject']).take(10).toList(),
      language: languages.length == 1 ? languages.first : '',
      sources: const [IsbnMetadataSource.openLibrary],
      approximate: true,
    );

    return book.hasUsableData ? book : null;
  }
}
