import 'package:equatable/equatable.dart';

abstract class ShelfViewEvent extends Equatable {
  const ShelfViewEvent();

  @override
  List<Object?> get props => [];
}

class LoadShelves extends ShelfViewEvent {
  const LoadShelves();
}

class CreateShelf extends ShelfViewEvent {
  final String shelfName;
  final bool isPublic;

  const CreateShelf(this.shelfName, {this.isPublic = false});

  @override
  List<Object?> get props => [shelfName, isPublic];
}

class RemoveShelfFromState extends ShelfViewEvent {
  final String shelfId;

  const RemoveShelfFromState(this.shelfId);

  @override
  List<Object?> get props => [shelfId];
}

class EditShelfState extends ShelfViewEvent {
  final String shelfId;
  final String newShelfName;
  final bool isPublic;

  const EditShelfState(
    this.shelfId,
    this.newShelfName, {
    required this.isPublic,
  });

  @override
  List<Object?> get props => [shelfId, newShelfName, isPublic];
}

class FindShelvesContainingBook extends ShelfViewEvent {
  final String bookId;

  const FindShelvesContainingBook(this.bookId);

  @override
  List<Object> get props => [bookId];
}

class AddBookToShelf extends ShelfViewEvent {
  final String bookId;
  final String shelfId;

  const AddBookToShelf({required this.bookId, required this.shelfId});

  @override
  List<Object> get props => [bookId, shelfId];
}

class RemoveBookFromShelf extends ShelfViewEvent {
  final String bookId;
  final String shelfId;

  const RemoveBookFromShelf({required this.bookId, required this.shelfId});

  @override
  List<Object> get props => [bookId, shelfId];
}
