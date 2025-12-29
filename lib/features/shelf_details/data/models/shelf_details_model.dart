import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';

class ShelfDetailsModel extends Equatable {
  final String name;
  final List<ShelfBookItem> books;
  final bool isPublic;

  const ShelfDetailsModel({
    required this.name,
    required this.books,
    this.isPublic = false,
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

    return ShelfDetailsModel(name: shelfName, books: books);
  }

  ShelfDetailsModel copyWith({
    String? name,
    List<ShelfBookItem>? books,
    bool? isPublic,
  }) {
    return ShelfDetailsModel(
      name: name ?? this.name,
      books: books ?? this.books,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [name, books, isPublic];
}
