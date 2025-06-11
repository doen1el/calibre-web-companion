import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';

import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';

class BookViewBloc extends Bloc<BookViewEvent, BookViewState> {
  final BookViewRepository _repository;
  final Logger _logger;

  BookViewBloc({required BookViewRepository repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger(),
      super(const BookViewState()) {
    on<LoadSettings>(_onLoadSettings);
    on<LoadBooks>(_onLoadBooks);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<RefreshBooks>(_onRefreshBooks);
    on<ChangeSort>(_onChangeSort);
    on<SearchBooks>(_onSearchBooks);
    on<UploadBook>(_onUploadBook);
    on<ChangeColumnCount>(_onChangeColumnCount);
    on<UploadCancel>(_onUploadCancel);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<BookViewState> emit,
  ) async {
    try {
      final columnCount = await _repository.getColumnCount();
      emit(state.copyWith(columnCount: columnCount));
    } catch (e) {
      _logger.e('Error loading settings: $e');
    }
  }

  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BookViewState> emit,
  ) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, hasError: false, errorMessage: ''));

    try {
      final books = await _repository.fetchBooks(
        offset: state.offset,
        limit: state.limit,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      final hasMoreBooks = books.length == state.limit;
      // Special case for authors sorting which has pagination issues
      final adjustedHasMoreBooks =
          state.sortBy == 'authors' ? true : hasMoreBooks;

      emit(
        state.copyWith(
          books: books,
          isLoading: false,
          hasMoreBooks: adjustedHasMoreBooks,
          offset: state.offset + books.length,
        ),
      );
    } catch (e) {
      _logger.e('Error loading books: $e');
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookViewState> emit,
  ) async {
    if (state.isLoading || !state.hasMoreBooks) return;

    emit(state.copyWith(isLoading: true));

    try {
      final moreBooks = await _repository.fetchBooks(
        offset: state.offset,
        limit: state.limit,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      final allBooks = [...state.books, ...moreBooks];
      final hasMoreBooks = moreBooks.length == state.limit;
      // Special case for authors sorting
      final adjustedHasMoreBooks =
          state.sortBy == 'authors' ? true : hasMoreBooks;

      emit(
        state.copyWith(
          books: allBooks,
          isLoading: false,
          hasMoreBooks: adjustedHasMoreBooks,
          offset: state.offset + moreBooks.length,
        ),
      );
    } catch (e) {
      _logger.e('Error loading more books: $e');
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshBooks(
    RefreshBooks event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        offset: 0,
        books: [],
        hasMoreBooks: true,
        isLoading: false,
        hasError: false,
        errorMessage: '',
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onChangeSort(
    ChangeSort event,
    Emitter<BookViewState> emit,
  ) async {
    _logger.i('Sorting by ${event.sortBy} ${event.sortOrder}');

    emit(
      state.copyWith(
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        offset: 0,
        books: [],
        hasMoreBooks: true,
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.query,
        offset: 0,
        books: [],
        hasMoreBooks: true,
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onUploadBook(
    UploadBook event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        uploadStatus: UploadStatus.loading,
        hasError: false,
        errorMessage: '',
      ),
    );

    try {
      emit(state.copyWith(uploadStatus: UploadStatus.uploading));

      final result = await _repository.uploadEbook(event.book);

      emit(
        state.copyWith(
          uploadStatus: result ? UploadStatus.success : UploadStatus.failed,
        ),
      );

      if (result) {
        add(const RefreshBooks());
      }
    } catch (e) {
      _logger.e('Error uploading book: $e');
      emit(
        state.copyWith(
          uploadStatus: UploadStatus.failed,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onChangeColumnCount(
    ChangeColumnCount event,
    Emitter<BookViewState> emit,
  ) async {
    try {
      await _repository.setColumnCount(event.count);
      emit(state.copyWith(columnCount: event.count));
    } catch (e) {
      _logger.e('Error changing column count: $e');
    }
  }

  void _onUploadCancel(UploadCancel event, Emitter<BookViewState> emit) {
    emit(state.copyWith(uploadStatus: UploadStatus.initial));
  }
}
