import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';

class ShelfDetailsModel extends Equatable {
  final String name;
  final List<ShelfBookItem> books;
  final bool isPublic;
  final int? nextOffset;

  const ShelfDetailsModel({
    required this.name,
    required this.books,
    this.isPublic = false,
    this.nextOffset,
  });

  factory ShelfDetailsModel.fromFeedJson(Map<String, dynamic> json) {
    final feed = json['feed'];
    final shelfName = feed['title'] as String? ?? 'Unknown Shelf';

    final entriesRaw = feed['entry'];
    List<dynamic> entries = [];

    if (entriesRaw is List) {
      entries = entriesRaw;
    } else if (entriesRaw is Map) {
      entries = [entriesRaw];
    }

    final books =
        entries.map((entry) {
          return ShelfBookItem.fromJson(entry as Map<String, dynamic>);
        }).toList();

    return ShelfDetailsModel(
      name: shelfName,
      books: books,
      nextOffset: _parseNextOffset(feed['link']),
    );
  }

  static int? _parseNextOffset(dynamic links) {
    if (links == null) return null;
    final linkList = links is List ? links : [links];
    for (final link in linkList) {
      if (link is! Map) continue;
      final rel = (link['_rel'] ?? link['rel'])?.toString();
      if (rel != 'next') continue;
      final href = (link['_href'] ?? link['href'])?.toString() ?? '';
      final offset = Uri.tryParse(href)?.queryParameters['offset'];
      if (offset != null) return int.tryParse(offset);
    }
    return null;
  }

  ShelfDetailsModel copyWith({
    String? name,
    List<ShelfBookItem>? books,
    bool? isPublic,
    int? nextOffset,
  }) {
    return ShelfDetailsModel(
      name: name ?? this.name,
      books: books ?? this.books,
      isPublic: isPublic ?? this.isPublic,
      nextOffset: nextOffset ?? this.nextOffset,
    );
  }

  @override
  List<Object?> get props => [name, books, isPublic, nextOffset];
}
