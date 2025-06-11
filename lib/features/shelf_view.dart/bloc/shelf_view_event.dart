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

  const CreateShelf(this.shelfName);

  @override
  List<Object?> get props => [shelfName];
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

  const EditShelfState(this.shelfId, this.newShelfName);

  @override
  List<Object?> get props => [shelfId, newShelfName];
}
