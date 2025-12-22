import 'package:equatable/equatable.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/book_author_model.dart';

class ShelfDetailsModel extends Equatable {
  final String name;
  final List<ShelfBookItem> books;
  final bool isPublic;

  const ShelfDetailsModel({
    required this.name,
    required this.books,
    this.isPublic = false,
  });

  factory ShelfDetailsModel.fromHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    return ShelfDetailsModel(
      name: _extractShelfName(document),
      books: _extractBooks(document),
    );
  }

  static String _extractShelfName(html.Document document) {
    return document
            .querySelector('h2')
            ?.text
            .replaceAll(RegExp(r"^[^']*'|'[^']*$"), '') ??
        "Unknown Shelf";
  }

  static List<ShelfBookItem> _extractBooks(html.Document document) {
    return document.querySelectorAll('.book').map(_extractBookItem).toList();
  }

  static ShelfBookItem _extractBookItem(html.Element bookElement) {
    final seriesInfo = _extractSeriesInfo(bookElement);

    return ShelfBookItem(
      id: _extractBookId(bookElement),
      title: _extractTitle(bookElement),
      authors: _extractAuthors(bookElement),
      seriesName: seriesInfo['name'],
      seriesId: seriesInfo['id'],
      seriesIndex: seriesInfo['index'],
    );
  }

  static String _extractTitle(html.Element bookElement) {
    return bookElement.querySelector('.title')?.text ?? "Unknown Title";
  }

  static List<BookAuthor> _extractAuthors(html.Element bookElement) {
    return bookElement
        .querySelectorAll('.author a')
        .map(
          (link) => BookAuthor(
            name: link.text,
            id: _extractIdFromUrl(link.attributes['href'] ?? ''),
          ),
        )
        .toList();
  }

  static Map<String, String?> _extractSeriesInfo(html.Element bookElement) {
    final seriesElement = bookElement.querySelector('.series');
    final seriesLink = seriesElement?.querySelector('a');

    if (seriesLink == null) {
      return {'name': null, 'id': null, 'index': null};
    }

    final seriesIndex = RegExp(
      r'\((\d+(?:\.\d+)?)\)',
    ).firstMatch(seriesElement!.text)?.group(1);

    return {
      'name': seriesLink.text.trim(),
      'id': _extractIdFromUrl(seriesLink.attributes['href'] ?? ''),
      'index': seriesIndex,
    };
  }

  static String _extractBookId(html.Element bookElement) {
    final href =
        bookElement.querySelector('a[data-toggle="modal"]')?.attributes['href'];

    return RegExp(r'/book/(\d+)').firstMatch(href ?? '')?.group(1) ?? '';
  }

  static String _extractIdFromUrl(String url) {
    return url
        .split('/')
        .lastWhere((part) => part.isNotEmpty, orElse: () => '');
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
