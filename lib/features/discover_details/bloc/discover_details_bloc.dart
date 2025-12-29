import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';

import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';

class DiscoverDetailsBloc
    extends Bloc<DiscoverDetailsEvent, DiscoverDetailsState> {
  final DiscoverDetailsRepository repository;

  DiscoverDetailsBloc({required this.repository})
    : super(const DiscoverDetailsState()) {
    on<LoadBooks>(_onLoadBooks);
    on<LoadCategories>(_onLoadCategories);
    on<LoadBooksFromPath>(_onLoadBooksFromPath);
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
        isNotFound: false,
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
      final isNotFound = e.toString().contains('404');
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
          isNotFound: isNotFound,
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
        isNotFound: false,
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
      final isNotFound = e.toString().contains('404');
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
          isNotFound: isNotFound,
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
        isNotFound: false,
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
      final isNotFound = e.toString().contains('404');
      emit(
        state.copyWith(
          status: DiscoverDetailsStatus.error,
          errorMessage: e.toString(),
          isNotFound: isNotFound,
        ),
      );
    }
  }
}
