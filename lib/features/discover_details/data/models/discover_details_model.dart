import 'package:equatable/equatable.dart';

class DiscoverDetailsModel extends Equatable {
  final String id;
  final String uuid;
  final String title;
  final String authors;
  final String? coverUrl;
  final String? summary;
  final List<String> tags;

  const DiscoverDetailsModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.summary,
    this.tags = const [],
  });

  factory DiscoverDetailsModel.fromJson(
    Map<String, dynamic> json,
    String baseUrl,
  ) {
    final title = json['title'] as String? ?? 'Unknown Title';

    String id = '';
    final rawId = json['id'] as String? ?? '';
    final uuid = rawId.replaceFirst('urn:uuid:', '');

    final links = json['link'];
    if (links != null) {
      final linkList = links is List ? links : [links];
      for (var link in linkList) {
        final href = link['_href'] as String?;
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            final segments = uri.pathSegments;
            for (var segment in segments) {
              if (RegExp(r'^\d+$').hasMatch(segment)) {
                id = segment;
                break;
              }
            }
          }
        }
        if (id.isNotEmpty) break;
      }
    }
    if (id.isEmpty) {
      final parts = rawId.split(':');
      if (parts.isNotEmpty && int.tryParse(parts.last) != null) {
        id = parts.last;
      } else {
        id = rawId;
      }
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

    String? coverUrl;
    if (links != null) {
      final linkList = links is List ? links : [links];
      final imageLink = linkList.firstWhere(
        (link) =>
            link is Map &&
            (link['_rel'] == 'http://opds-spec.org/image' ||
                link['_rel'] == 'http://opds-spec.org/image/thumbnail'),
        orElse: () => null,
      );

      if (imageLink != null && imageLink['_href'] != null) {
        coverUrl = imageLink['_href'].toString();
      }
    }

    String? summary;
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

    List<String> tags = [];
    if (json['category'] != null) {
      final cats =
          json['category'] is List ? json['category'] : [json['category']];
      for (var c in cats) {
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

    return DiscoverDetailsModel(
      id: id,
      uuid: uuid,
      title: title,
      authors: authors,
      coverUrl: coverUrl,
      summary: summary,
      tags: tags,
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
  List<Object?> get props => [id, title, authors, coverUrl, summary, tags];
}
