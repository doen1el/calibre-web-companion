import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';

class DiscoverDetailsBloc
    extends Bloc<DiscoverDetailsEvent, DiscoverDetailsState> {
  final DiscoverDetailsRepository repository;

  DiscoverDetailsBloc({required this.repository})
    : super(const DiscoverDetailsState()) {
    on<LoadBooks>(_onLoadBooks);
    on<LoadCategories>(_onLoadCategories);
    on<LoadBooksFromPath>(_onLoadBooksFromPath);
    on<LoadDiscoverBookDetails>(_onLoadDiscoverBookDetails);
  }

  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DiscoverDetailsStatus.loading,
        isShowingBooks: true,
        isShowingCategories: false,
      ),
    );
    try {
      final bookFeed = await repository.loadBooks(
        event.type,
        subPath: event.subPath,
      );

      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.loaded,
          bookFeed: bookFeed,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DiscoverDetailsStatus.loading,
        isShowingBooks: false,
        isShowingCategories: true,
      ),
    );

    try {
      final categoryFeed = await repository.loadCategories(
        event.type,
        subPath: event.subPath,
      );

      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.loaded,
          categoryFeed: categoryFeed,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadBooksFromPath(
    LoadBooksFromPath event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DiscoverDetailsStatus.loading,
        isShowingBooks: true,
        isShowingCategories: false,
      ),
    );

    try {
      final bookFeed = await repository.loadBooksFromPath(event.fullPath);

      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.loaded,
          bookFeed: bookFeed,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadDiscoverBookDetails(
    LoadDiscoverBookDetails event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    emit(state.copyWith(loadingBookId: event.bookId));

    try {
      final bookDetails = await repository.loadBookDetails(event.bookId);

      emit(state.copyWith(bookDetails: bookDetails, errorMessage: null));

      // ignore: use_build_context_synchronously
      await Navigator.of(event.context).push(
        AppTransitions.createSlideRoute(
          BookDetailsPage(
            bookViewModel: bookDetails,
            bookUuid: bookDetails.uuid,
          ),
        ),
      );

      emit(state.copyWith(loadingBookId: ""));
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
          loadingBookId: "",
        ),
      );
    }
  }
}
