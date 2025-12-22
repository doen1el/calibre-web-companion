import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';

abstract class ShelfDetailsEvent extends Equatable {
  const ShelfDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadShelfDetails extends ShelfDetailsEvent {
  final String shelfId;
  final bool isPublic;

  const LoadShelfDetails(this.shelfId, {this.isPublic = false});

  @override
  List<Object?> get props => [shelfId, isPublic];
}

class RemoveFromShelf extends ShelfDetailsEvent {
  final String shelfId;
  final String bookId;

  const RemoveFromShelf(this.shelfId, this.bookId);

  @override
  List<Object?> get props => [shelfId, bookId];
}

class EditShelf extends ShelfDetailsEvent {
  final String shelfId;
  final String newShelfName;
  final bool isPublic;

  const EditShelf(this.shelfId, this.newShelfName, {this.isPublic = false});

  @override
  List<Object?> get props => [shelfId, newShelfName, isPublic];
}

class DeleteShelf extends ShelfDetailsEvent {
  final String shelfId;

  const DeleteShelf(this.shelfId);

  @override
  List<Object?> get props => [shelfId];
}

class NavigateToBook extends ShelfDetailsEvent {
  final ShelfBookItem book;

  const NavigateToBook(this.book);

  @override
  List<Object?> get props => [book];
}
