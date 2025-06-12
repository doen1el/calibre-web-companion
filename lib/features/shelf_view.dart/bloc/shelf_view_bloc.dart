import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_state.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repositorie.dart';

class ShelfViewBloc extends Bloc<ShelfViewEvent, ShelfViewState> {
  final ShelfViewRepository repository;

  ShelfViewBloc({required this.repository}) : super(const ShelfViewState()) {
    on<LoadShelves>(_onLoadShelves);
    on<CreateShelf>(_onCreateShelf);
    on<RemoveShelfFromState>(_onRemoveShelfFromState);
    on<EditShelfState>(_onEditShelfState);
    on<FindShelvesContainingBook>(_onFindShelvesContainingBook);
    on<AddBookToShelf>(_onAddBookToShelf);
    on<RemoveBookFromShelf>(_onRemoveBookFromShelf);
  }

  Future<void> _onLoadShelves(
    LoadShelves event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(createShelfStatus: CreateShelfStatus.initial));
    emit(state.copyWith(status: ShelfViewStatus.loading));

    try {
      final shelves = await repository.loadShelves();
      emit(
        state.copyWith(
          status: ShelfViewStatus.loaded,
          shelves: shelves.shelves,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfViewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateShelf(
    CreateShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(createShelfStatus: CreateShelfStatus.loading));

    try {
      final newShelfId = await repository.createShelf(event.shelfName);

      final newShelf = ShelfViewModel(id: newShelfId, title: event.shelfName);

      final updatedShelves = List.of(state.shelves)..add(newShelf);

      emit(
        state.copyWith(
          createShelfStatus: CreateShelfStatus.success,
          shelves: updatedShelves,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          createShelfStatus: CreateShelfStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemoveShelfFromState(
    RemoveShelfFromState event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(actionMessage: null));

    final updatedShelves = List.of(state.shelves);
    updatedShelves.removeWhere((shelf) => shelf.id == event.shelfId);

    emit(
      state.copyWith(
        status: ShelfViewStatus.loaded,
        shelves: updatedShelves,
        actionMessage: 'Shelf removed successfully',
      ),
    );
  }

  Future<void> _onEditShelfState(
    EditShelfState event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(actionMessage: null));

    final updatedShelves =
        state.shelves.map((shelf) {
          if (shelf.id == event.shelfId) {
            return shelf.copyWith(title: event.newShelfName);
          }
          return shelf;
        }).toList();

    emit(
      state.copyWith(
        status: ShelfViewStatus.loaded,
        shelves: updatedShelves,
        actionMessage: 'Shelf updated successfully',
      ),
    );
  }

  Future<void> _onFindShelvesContainingBook(
    FindShelvesContainingBook event,
    Emitter<ShelfViewState> emit,
  ) async {
    try {
      emit(state.copyWith(bookIdBeingChecked: event.bookId));

      final containingShelves = await repository.findShelvesContainingBook(
        event.bookId,
      );

      emit(state.copyWith(bookInShelves: containingShelves));
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfViewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddBookToShelf(
    AddBookToShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    try {
      await repository.addBookToShelf(
        shelfId: event.shelfId,
        bookId: event.bookId,
      );

      // Aktualisiere die Liste der Regale, die das Buch enthalten
      if (state.bookIdBeingChecked == event.bookId) {
        final shelf = state.shelves.firstWhere((s) => s.id == event.shelfId);
        final updatedShelves = List<ShelfViewModel>.from(state.bookInShelves);
        if (!updatedShelves.any((s) => s.id == shelf.id)) {
          updatedShelves.add(shelf);
        }

        emit(state.copyWith(bookInShelves: updatedShelves));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfViewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemoveBookFromShelf(
    RemoveBookFromShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    try {
      await repository.removeBookFromShelf(
        shelfId: event.shelfId,
        bookId: event.bookId,
      );

      // Aktualisiere die Liste der Regale, die das Buch enthalten
      if (state.bookIdBeingChecked == event.bookId) {
        final updatedShelves =
            state.bookInShelves
                .where((shelf) => shelf.id != event.shelfId)
                .toList();

        emit(state.copyWith(bookInShelves: updatedShelves));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfViewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
