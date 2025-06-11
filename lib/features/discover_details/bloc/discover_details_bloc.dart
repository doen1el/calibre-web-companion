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
    on<RefreshData>(_onRefreshData);
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

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    // Reload the current data based on what was loaded last
    if (state.isShowingBooks && state.bookFeed != null) {
      // Re-trigger the last books load
      // This would need to be enhanced to store the last parameters
    } else if (state.isShowingCategories && state.categoryFeed != null) {
      // Re-trigger the last categories load
      // This would need to be enhanced to store the last parameters
    }
  }
}
