import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_utils.dart';

class BnfProvider extends IsbnMetadataProvider {
  BnfProvider({super.client, super.logger});

  @override
  IsbnMetadataSource get source => IsbnMetadataSource.bnf;

  @override
  Future<IsbnBook?> lookup(String isbn) async {
    final isbn10 = toIsbn10(isbn);
    final query = [
      'bib.isbn all "$isbn"',
      if (isbn10 != null && isbn10 != isbn) 'bib.isbn all "$isbn10"',
    ].join(' or ');

    final uri = Uri.https('catalogue.bnf.fr', '/api/SRU', {
      'version': '1.2',
      'operation': 'searchRetrieve',
      'query': query,
      'recordSchema': 'dublincore',
      'maximumRecords': '1',
    });

    final body = await fetchBody(uri, headers: {'Accept': 'application/xml'});
    if (body == null || body.isEmpty) return null;
    if (!body.contains('<dc:') && !body.contains('<title')) return null;

    final creators = _tagValues(body, 'creator');
    final writers = creators.where(_isWriter).toList();
    final authors =
        (writers.isEmpty ? creators : writers)
            .map(cleanCatalogAuthor)
            .where((a) => a.isNotEmpty)
            .toList();

    final book = IsbnBook(
      isbn: isbn,
      title: _stripCatalogSuffix(_tagValue(body, 'title')),
      authors: authors,
      publisher: _stripPlace(_tagValue(body, 'publisher')),
      publishDate: _year(_tagValue(body, 'date')),
      pageCount: _pageCount(_tagValues(body, 'format').join(' ')),
      subjects: _tagValues(body, 'subject').take(10).toList(),
      description:
          _tagValues(body, 'description').where(_isProse).join(' ').trim(),
      language: _tagValue(body, 'language'),
      sources: const [IsbnMetadataSource.bnf],
    );

    return book.hasUsableData ? book : null;
  }

  List<String> _tagValues(String xml, String tag) {
    final pattern = RegExp(
      '<(?:[A-Za-z0-9]+:)?$tag(?:\\s[^>]*)?>(.*?)</(?:[A-Za-z0-9]+:)?$tag>',
      dotAll: true,
      caseSensitive: false,
    );
    return pattern
        .allMatches(xml)
        .map((m) => IsbnMetadataProvider.cleanText(m[1]))
        .where((v) => v.isNotEmpty)
        .toList();
  }

  String _tagValue(String xml, String tag) {
    final values = _tagValues(xml, tag);
    return values.isEmpty ? '' : values.first;
  }

  String _stripCatalogSuffix(String title) {
    final cut = title.indexOf(' / ');
    return (cut > 0 ? title.substring(0, cut) : title).trim();
  }

  bool _isWriter(String creator) {
    final role = creator.split(RegExp(r'\)\s*\.?\s*')).last.toLowerCase();
    if (role.isEmpty || role == creator.toLowerCase()) return true;
    return role.contains('auteur') || role.contains('autrice');
  }

  String _stripPlace(String publisher) =>
      publisher.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

  bool _isProse(String text) {
    final lower = text.toLowerCase();
    return !lower.startsWith('code à barres') &&
        !lower.startsWith('collection :') &&
        !lower.startsWith('notice réd') &&
        !lower.startsWith('bibliogr') &&
        !lower.contains('ean ') &&
        !lower.contains('isbn ');
  }

  String _year(String raw) {
    final match = RegExp(r'\d{4}').firstMatch(raw);
    return match?.group(0) ?? raw;
  }

  int? _pageCount(String format) {
    final match = RegExp(r'(\d+)\s*p\b').firstMatch(format);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}
