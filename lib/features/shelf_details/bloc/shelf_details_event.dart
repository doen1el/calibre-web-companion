import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';

abstract class ShelfDetailsEvent extends Equatable {
  const ShelfDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadShelfDetails extends ShelfDetailsEvent {
  final String shelfId;

  const LoadShelfDetails(this.shelfId);

  @override
  List<Object?> get props => [shelfId];
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

  const EditShelf(this.shelfId, this.newShelfName);

  @override
  List<Object?> get props => [shelfId, newShelfName];
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

class LoadShelfBookDetails extends ShelfDetailsEvent {
  final String bookId;
  final BuildContext context;

  const LoadShelfBookDetails(this.bookId, this.context);

  @override
  List<Object?> get props => [bookId];
}
