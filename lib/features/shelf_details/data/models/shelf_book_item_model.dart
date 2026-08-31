import 'package:calibre_web_companion/core/utils/book_mime_types.dart';
import 'package:equatable/equatable.dart';

class ShelfBookItem extends Equatable {
  final String id;
  final String uuid;
  final String title;
  final String authors;
  final String? coverUrl;
  final String summary;
  final List<String> tags;
  final List<String> formats;

  const ShelfBookItem({
    required this.id,
    required this.uuid,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.summary = '',
    this.tags = const [],
    this.formats = const [],
  });

  factory ShelfBookItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Unknown Title';

    String id = '';
    final rawId = json['id'] as String? ?? '';

    if (rawId.startsWith('urn:booklore:book:')) {
      id = rawId.replaceFirst('urn:booklore:book:', '');
    } else {
      id = rawId.replaceFirst('urn:uuid:', '');
    }

    final uuid = rawId.replaceFirst('urn:uuid:', '');

    String? coverUrl;
    final List<String> formats = [];

    final links = json['link'];
    if (links != null) {
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
            if (coverUrl == null || rel == 'http://opds-spec.org/image') {
              coverUrl = href as String?;
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
          }
        }
      }
    }

    if (id.isEmpty) {
      id = rawId;
    }

    String authors = '';
    final authorRaw = json['author'];
    if (authorRaw != null) {
      if (authorRaw is List) {
        authors = authorRaw.map((a) => _parseAuthor(a).toString()).join(', ');
      } else if (authorRaw is Map) {
        authors = _parseAuthor(authorRaw).toString();
      }
    }

    String summary = '';
    if (json.containsKey('content')) {
      final content = json['content'];
      if (content is Map) {
        summary = content['__cdata'] ?? content['#text'] ?? content.toString();
      } else {
        summary = content.toString();
      }
    } else if (json.containsKey('summary')) {
      final sum = json['summary'];
      if (sum is Map) {
        summary = sum['__cdata'] ?? sum['#text'] ?? sum.toString();
      } else {
        summary = sum.toString();
      }
    }

    final List<String> tags = [];
    if (json['category'] != null) {
      final cats =
          json['category'] is List ? json['category'] : [json['category']];
      for (final c in cats) {
        if (c is Map) {
          final term = c['term'] ?? c['_term'] ?? c['label'] ?? c['@term'];
          if (term != null && term.toString().isNotEmpty) {
            tags.add(term.toString());
          }
        } else if (c is String) {
          tags.add(c);
        }
      }
    }

    return ShelfBookItem(
      id: id,
      uuid: uuid,
      title: title,
      authors: authors,
      coverUrl: coverUrl,
      summary: summary,
      tags: tags,
      formats: formats,
    );
  }

  static String _parseAuthor(dynamic json) {
    if (json is Map) {
      final name = json['name'] as String? ?? 'Unknown Author';
      return name;
    }
    return 'Unknown Author';
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    title,
    authors,
    coverUrl,
    summary,
    tags,
    formats,
  ];
}
