import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repository.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_event.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_state.dart';

class ShelfDetailsBloc extends Bloc<ShelfDetailsEvent, ShelfDetailsState> {
  final ShelfDetailsRepository repository;
  final ShelfViewBloc shelfViewBloc;

  ShelfDetailsBloc({required this.repository, required this.shelfViewBloc})
    : super(const ShelfDetailsState()) {
    on<LoadShelfDetails>(_onLoadShelfDetails);
    on<RemoveFromShelf>(_onRemoveFromShelf);
    on<EditShelf>(_onEditShelf);
    on<DeleteShelf>(_onDeleteShelf);
    on<LoadShelfBookDetails>(_onLoadShelfBookDetails);
  }

  Future<void> _onLoadShelfDetails(
    LoadShelfDetails event,
    Emitter<ShelfDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ShelfDetailsStatus.loading));

    try {
      final result = await repository.getShelfDetails(event.shelfId);

      emit(
        state.copyWith(
          status: ShelfDetailsStatus.loaded,
          currentShelfDetail: result,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemoveFromShelf(
    RemoveFromShelf event,
    Emitter<ShelfDetailsState> emit,
  ) async {
    emit(state.copyWith(actionDetailsStatus: ShelfDetailsActionStatus.loading));

    try {
      final success = await repository.removeFromShelf(
        event.shelfId,
        event.bookId,
      );

      if (success) {
        emit(
          state.copyWith(
            actionDetailsStatus: ShelfDetailsActionStatus.success,
            actionMessage: 'Book removed from shelf successfully',
          ),
        );

        shelfViewBloc.add(RemoveShelfFromState(event.shelfId));
      } else {
        emit(
          state.copyWith(
            actionDetailsStatus: ShelfDetailsActionStatus.error,
            actionMessage: 'Failed to remove book from shelf',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionDetailsStatus: ShelfDetailsActionStatus.error,
          actionMessage: e.toString(),
        ),
      );
      return;
    }
  }

  Future<void> _onEditShelf(
    EditShelf event,
    Emitter<ShelfDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        actionDetailsStatus: ShelfDetailsActionStatus.loading,
        actionMessage: null,
      ),
    );

    try {
      final success = await repository.editShelf(
        event.shelfId,
        event.newShelfName,
      );
      if (success) {
        emit(
          state.copyWith(
            currentShelfDetail: state.currentShelfDetail!.copyWith(
              name: event.newShelfName,
            ),
            actionDetailsStatus: ShelfDetailsActionStatus.success,
            actionMessage: 'Shelf edited successfully',
          ),
        );

        shelfViewBloc.add(EditShelfState(event.shelfId, event.newShelfName));
      } else {
        emit(
          state.copyWith(
            actionDetailsStatus: ShelfDetailsActionStatus.error,
            actionMessage: 'Failed to edit shelf',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionDetailsStatus: ShelfDetailsActionStatus.error,
          actionMessage: e.toString(),
        ),
      );
      return;
    }
  }

  Future<void> _onDeleteShelf(
    DeleteShelf event,
    Emitter<ShelfDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        actionDetailsStatus: ShelfDetailsActionStatus.loading,
        actionMessage: null,
      ),
    );

    try {
      final success = await repository.deleteShelf(event.shelfId);

      if (success) {
        emit(
          state.copyWith(
            actionDetailsStatus: ShelfDetailsActionStatus.success,
            actionMessage: 'Shelf deleted successfully',
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionDetailsStatus: ShelfDetailsActionStatus.error,
            actionMessage: 'Failed to delete shelf',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionDetailsStatus: ShelfDetailsActionStatus.error,
          actionMessage: e.toString(),
        ),
      );
      return;
    }
  }

  Future<void> _onLoadShelfBookDetails(
    LoadShelfBookDetails event,
    Emitter<ShelfDetailsState> emit,
  ) async {
    emit(state.copyWith(loadingBookId: event.bookId));

    try {
      final bookDetails = await repository.loadBookDetails(event.bookId);

      emit(state.copyWith(bookDetails: bookDetails, errorMessage: null));

      // ignore: use_build_context_synchronously
      await Navigator.of(event.context).push(
        AppTransitions.createSlideRoute(
          BookDetailsPage(
            bookListModel: bookDetails,
            bookUuid: bookDetails.uuid,
          ),
        ),
      );

      emit(state.copyWith(loadingBookId: ""));
    } catch (e) {
      emit(
        state.copyWith(
          status: ShelfDetailsStatus.error,
          errorMessage: e.toString(),
          loadingBookId: "",
        ),
      );
    }
  }
}
