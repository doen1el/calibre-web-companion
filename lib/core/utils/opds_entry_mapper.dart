import 'package:calibre_web_companion/core/utils/book_mime_types.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Maps an OPDS `<entry>` (as converted by xml2json) to a book. With
/// [baseUri], cover and download links are resolved against it.
BookViewModel? mapOpdsEntry(dynamic entry, {Uri? baseUri}) {
  try {
    if (entry is! Map) return null;

    final title = entry['title'] ?? 'Unknown Title';

    final rawId = entry['id'] ?? '';
    final uuid = rawId.toString().replaceFirst('urn:uuid:', '');

    int id = 0;

    final parts = rawId.toString().split(':');
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      final parsed = int.tryParse(lastPart);
      if (parsed != null) {
        id = parsed;
      }
    }

    if (id == 0 && entry.containsKey('link')) {
      final links = entry['link'];
      final linkList = links is List ? links : [links];
      for (final link in linkList) {
        if (link is Map && link['_href'] != null) {
          final href = link['_href'].toString();
          final uri = Uri.tryParse(href);
          if (uri != null) {
            for (final segment in uri.pathSegments) {
              if (RegExp(r'^\d+$').hasMatch(segment)) {
                id = int.parse(segment);
                break;
              }
            }
          }
        }
      }
    }

    String authors = 'Unknown';
    if (entry.containsKey('author')) {
      final authorData = entry['author'];
      if (authorData is Map && authorData.containsKey('name')) {
        authors = authorData['name'];
      } else if (authorData is List) {
        authors = authorData.map((a) => a['name']).join(', ');
      }
    }

    bool hasCover = false;
    String? coverUrl;
    final List<String> formats = [];
    final Map<String, String> downloadLinks = {};

    if (entry.containsKey('link')) {
      final links = entry['link'];
      final linkList = links is List ? links : [links];

      for (final link in linkList) {
        if (link is Map) {
          final rel = link['_rel'] ?? link['rel'];
          final type = link['_type'] ?? link['type'];
          final href = link['_href'] ?? link['href'];

          final isAcquisition =
              rel != null &&
              rel.toString().startsWith('http://opds-spec.org/acquisition');

          if (rel == 'http://opds-spec.org/image' ||
              rel == 'http://opds-spec.org/image/thumbnail' ||
              (!isAcquisition &&
                  type != null &&
                  type.toString().startsWith('image/'))) {
            hasCover = true;
            if (href != null) {
              coverUrl = _resolve(href.toString(), baseUri);
            }
          }

          if (isAcquisition) {
            final format = bookFormatFromAcquisition(
              mimeType: type?.toString(),
              href: href?.toString(),
            );
            if (format != null && !formats.contains(format)) {
              formats.add(format);
            }
            if (format != null && href != null && baseUri != null) {
              downloadLinks.putIfAbsent(
                format,
                () => _resolve(href.toString(), baseUri),
              );
            }
          }
        }
      }
    }

    String pubdate = '';
    if (entry.containsKey('published')) {
      pubdate = entry['published'];
    }

    final List<String> tags = [];
    if (entry.containsKey('category')) {
      final categories = entry['category'];
      final categoryList = categories is List ? categories : [categories];
      for (final cat in categoryList) {
        if (cat is Map) {
          final term =
              cat['term'] ?? cat['_term'] ?? cat['label'] ?? cat['_label'];
          if (term != null && term.toString().isNotEmpty) {
            tags.add(term.toString());
          }
        }
      }
    }

    String description = '';
    if (entry.containsKey('content')) {
      final content = entry['content'];
      if (content is Map) {
        description =
            content['__cdata'] ??
            content['#text'] ??
            content['value'] ??
            content.toString();
      } else {
        description = content.toString();
      }
    } else if (entry.containsKey('summary')) {
      final summary = entry['summary'];
      if (summary is Map) {
        description =
            summary['__cdata'] ??
            summary['#text'] ??
            summary['value'] ??
            summary.toString();
      } else {
        description = summary.toString();
      }
    }

    return BookViewModel(
      id: id,
      uuid: uuid,
      title: title,
      authors: authors,
      hasCover: hasCover,
      pubdate: pubdate,
      data: description,
      path: '',
      series: entry['calibre:series']?.toString() ?? '',
      seriesIndex:
          double.tryParse(entry['calibre:series_index']?.toString() ?? '') ?? 0,
      coverUrl: coverUrl,
      formats: formats.isNotEmpty ? formats : const [],
      tags: tags,
      downloadLinks: downloadLinks,
    );
  } catch (e) {
    _logger.w('Error mapping OPDS entry: $e');
    return null;
  }
}

String _resolve(String href, Uri? baseUri) =>
    baseUri == null ? href : baseUri.resolve(href).toString();
