import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/book_author_model.dart';

class ShelfBookItem extends Equatable {
  final String id;
  final String title;
  final List<BookAuthor> authors;
  final String? seriesName;
  final String? seriesId;
  final String? seriesIndex;

  const ShelfBookItem({
    required this.id,
    required this.title,
    required this.authors,
    this.seriesName,
    this.seriesId,
    this.seriesIndex,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    authors,
    seriesName,
    seriesId,
    seriesIndex,
  ];
}
