import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiscoverDetailsBloc
    extends Bloc<DiscoverDetailsEvent, DiscoverDetailsState> {
  final DiscoverDetailsRepository repository;

  DiscoverDetailsBloc({required this.repository})
    : super(const DiscoverDetailsState()) {
    on<LoadBooks>(_onLoadBooks);
    on<LoadCategories>(_onLoadCategories);
    on<LoadBooksFromPath>(_onLoadBooksFromPath);
    on<LoadMoreDiscoverBooks>(_onLoadMoreDiscoverBooks);
    on<LoadMoreDiscoverCategories>(_onLoadMoreDiscoverCategories);
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

  Future<void> _onLoadMoreDiscoverBooks(
    LoadMoreDiscoverBooks event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    final currentFeed = state.bookFeed;
    final nextPageUrl = currentFeed?.nextPageUrl;

    if (state.isLoadingMore || currentFeed == null || nextPageUrl == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await repository.loadBooksFromPath(nextPageUrl);

      final existingIds = currentFeed.books.map((b) => b.id).toSet();
      final newBooks = page.books.where((b) => !existingIds.contains(b.id));

      emit(
        state.copyWith(
          bookFeed: DiscoverFeedModel(
            books: [...currentFeed.books, ...newBooks],
            nextPageUrl: _nextOrStop(nextPageUrl, page.nextPageUrl),
          ),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onLoadMoreDiscoverCategories(
    LoadMoreDiscoverCategories event,
    Emitter<DiscoverDetailsState> emit,
  ) async {
    final currentFeed = state.categoryFeed;
    final nextPageUrl = currentFeed?.nextPageUrl;

    if (state.isLoadingMore || currentFeed == null || nextPageUrl == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await repository.loadCategoriesFromPath(nextPageUrl);

      final existingIds = currentFeed.categories.map((c) => c.id).toSet();
      final newCategories = page.categories.where(
        (c) => !existingIds.contains(c.id),
      );

      emit(
        state.copyWith(
          categoryFeed: CategoryFeed(
            categories: [...currentFeed.categories, ...newCategories],
            nextPageUrl: _nextOrStop(nextPageUrl, page.nextPageUrl),
          ),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Guards against servers that keep pointing at the page we just loaded
  String? _nextOrStop(String loadedUrl, String? nextUrl) =>
      nextUrl == loadedUrl ? null : nextUrl;
}
