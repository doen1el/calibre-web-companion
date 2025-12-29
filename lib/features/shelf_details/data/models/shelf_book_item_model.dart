import 'package:equatable/equatable.dart';

class ShelfBookItem extends Equatable {
  final String id;
  final String uuid;
  final String title;
  final String authors;

  const ShelfBookItem({
    required this.id,
    required this.uuid,
    required this.title,
    required this.authors,
  });

  factory ShelfBookItem.fromJson(Map<String, dynamic> json) {
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

    return ShelfBookItem(id: id, uuid: uuid, title: title, authors: authors);
  }

  static String _parseAuthor(dynamic json) {
    if (json is Map) {
      final name = json['name'] as String? ?? 'Unknown Author';
      return name;
    }
    return 'Unknown Author';
  }

  @override
  List<Object?> get props => [id, uuid, title, authors];
}
