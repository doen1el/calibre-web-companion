import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_state.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';

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
    on<DeleteMagicShelf>(_onDeleteMagicShelf);
    on<DuplicateMagicShelf>(_onDuplicateMagicShelf);
    on<HideMagicShelf>(_onHideMagicShelf);
  }

  Future<void> _onLoadShelves(
    LoadShelves event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(createShelfStatus: CreateShelfStatus.initial));
    emit(state.copyWith(status: ShelfViewStatus.loading));

    try {
      final isOpds = repository.getIsOpds();
      final shelvesFuture = repository.loadShelves();
      final Future<List<MagicShelfModel>>? magicFuture =
          isOpds ? null : repository.loadMagicShelves().then((m) => m.shelves);

      final shelves = await shelvesFuture;

      var supportsMagic = false;
      var magicShelves = const <MagicShelfModel>[];
      if (magicFuture != null) {
        try {
          magicShelves = await magicFuture;
          supportsMagic = true;
        } catch (_) {}
      }

      emit(
        state.copyWith(
          status: ShelfViewStatus.loaded,
          shelves: shelves.shelves,
          isOpds: isOpds,
          supportsMagicShelves: supportsMagic,
          magicShelves: magicShelves,
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

  Future<void> _onDeleteMagicShelf(
    DeleteMagicShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(magicActionStatus: MagicShelfActionStatus.loading));
    try {
      await repository.deleteMagicShelf(event.shelfId);
      final updated =
          state.magicShelves.where((s) => s.id != event.shelfId).toList();
      emit(
        state.copyWith(
          magicShelves: updated,
          magicActionStatus: MagicShelfActionStatus.success,
          magicActionMessage: 'deleted',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          magicActionStatus: MagicShelfActionStatus.error,
          magicActionMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDuplicateMagicShelf(
    DuplicateMagicShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(magicActionStatus: MagicShelfActionStatus.loading));
    try {
      await repository.duplicateMagicShelf(event.shelfId);
      final magic = await repository.loadMagicShelves();
      emit(
        state.copyWith(
          magicShelves: magic.shelves,
          magicActionStatus: MagicShelfActionStatus.success,
          magicActionMessage: 'duplicated',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          magicActionStatus: MagicShelfActionStatus.error,
          magicActionMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onHideMagicShelf(
    HideMagicShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(state.copyWith(magicActionStatus: MagicShelfActionStatus.loading));
    try {
      await repository.hideMagicShelf(event.shelfId);
      final updated =
          state.magicShelves.where((s) => s.id != event.shelfId).toList();
      emit(
        state.copyWith(
          magicShelves: updated,
          magicActionStatus: MagicShelfActionStatus.success,
          magicActionMessage: 'hidden',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          magicActionStatus: MagicShelfActionStatus.error,
          magicActionMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateShelf(
    CreateShelf event,
    Emitter<ShelfViewState> emit,
  ) async {
    emit(
      state.copyWith(
        actionMessage: null,
        errorMessage: null,
        createShelfStatus: CreateShelfStatus.initial,
      ),
    );

    final normalizedNewName = event.shelfName.trim();
    final targetTitle =
        event.isPublic ? '$normalizedNewName (Public)' : normalizedNewName;

    final exists = state.shelves.any(
      (shelf) => shelf.title.trim().toLowerCase() == targetTitle.toLowerCase(),
    );

    if (exists) {
      emit(
        state.copyWith(
          createShelfStatus: CreateShelfStatus.error,
          errorMessage: 'Shelf with this name already exists',
        ),
      );
      return;
    }

    emit(state.copyWith(createShelfStatus: CreateShelfStatus.loading));

    try {
      final newShelfId = await repository.createShelf(
        event.shelfName,
        event.isPublic,
      );

      final newShelf = ShelfViewModel(
        id: newShelfId,
        title: event.isPublic ? '${event.shelfName} (Public)' : event.shelfName,
        isPublic: event.isPublic,
      );

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
        createShelfStatus: CreateShelfStatus.initial,
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
            final displayTitle =
                event.isPublic
                    ? '${event.newShelfName} (Public)'
                    : event.newShelfName;

            return shelf.copyWith(
              title: displayTitle,
              isPublic: event.isPublic,
            );
          }
          return shelf;
        }).toList();

    emit(
      state.copyWith(
        status: ShelfViewStatus.loaded,
        shelves: updatedShelves,
        actionMessage: 'Shelf updated successfully',
        createShelfStatus: CreateShelfStatus.initial,
      ),
    );
  }

  Future<void> _onFindShelvesContainingBook(
    FindShelvesContainingBook event,
    Emitter<ShelfViewState> emit,
  ) async {
    try {
      emit(
        state.copyWith(checkBookInShelfStatus: CheckBookInShelfStatus.loading),
      );

      final containingShelves = await repository.findShelvesContainingBook(
        event.bookId,
      );

      emit(
        state.copyWith(
          bookInShelves: containingShelves,
          checkBookInShelfStatus: CheckBookInShelfStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          checkBookInShelfStatus: CheckBookInShelfStatus.error,
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

      final shelf = state.shelves.firstWhere((s) => s.id == event.shelfId);
      final updatedShelves = List<ShelfViewModel>.from(state.bookInShelves);
      if (!updatedShelves.any((s) => s.id == shelf.id)) {
        updatedShelves.add(shelf);
      }

      emit(state.copyWith(bookInShelves: updatedShelves));
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

      final updatedShelves =
          state.bookInShelves
              .where((shelf) => shelf.id != event.shelfId)
              .toList();

      emit(state.copyWith(bookInShelves: updatedShelves));
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
