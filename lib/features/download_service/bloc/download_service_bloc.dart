import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_state.dart';

import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';

class DownloadServiceBloc
    extends Bloc<DownloadServiceEvent, DownloadServiceState> {
  final DownloadServiceRepository repository;
  final Logger logger;

  DownloadServiceBloc({required this.repository, required this.logger})
    : super(const DownloadServiceState()) {
    on<SearchBooks>(_onSearchBooks);
    on<DownloadBook>(_onDownloadBook);
    on<GetDownloadStatus>(_onGetDownloadStatus);
    on<ClearSearchResults>(_onClearSearchResults);
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<DownloadServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        searchStatus: DownloadServiceStatus.loading,
        hasSearched: true,
      ),
    );

    try {
      final results = await repository.searchBooks(
        event.query,
        filter: event.filter,
      );

      emit(
        state.copyWith(
          searchResults: results,
          searchStatus: DownloadServiceStatus.loaded,
        ),
      );
    } catch (e) {
      logger.e('Error in _onSearchBooks: $e');
      emit(
        state.copyWith(
          searchStatus: DownloadServiceStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDownloadBook(
    DownloadBook event,
    Emitter<DownloadServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        downloadStatus: DownloadServiceStatus.loading,
        downloadingBookId: event.bookId,
        errorMessage: null,
      ),
    );

    try {
      final success = await repository.downloadBook(event.bookId);
      if (success) {
        emit(
          state.copyWith(
            downloadStatus: DownloadServiceStatus.loaded,
            downloadingBookId: null,
          ),
        );

        add(GetDownloadStatus());
      } else {
        emit(
          state.copyWith(
            downloadStatus: DownloadServiceStatus.error,
            downloadingBookId: null,
            errorMessage: 'Failed to download book',
          ),
        );
      }
    } catch (e) {
      logger.e('Error in _onDownloadBook: $e');
      emit(
        state.copyWith(
          downloadStatus: DownloadServiceStatus.error,
          downloadingBookId: null,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetDownloadStatus(
    GetDownloadStatus event,
    Emitter<DownloadServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        statusLoadingStatus: DownloadServiceStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final books = await repository.getDownloadStatus();
      emit(
        state.copyWith(
          statusLoadingStatus: DownloadServiceStatus.loaded,
          books: books,
        ),
      );
    } catch (e) {
      logger.e('Error in _onGetDownloadStatus: $e');
      emit(
        state.copyWith(
          statusLoadingStatus: DownloadServiceStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearSearchResults(
    ClearSearchResults event,
    Emitter<DownloadServiceState> emit,
  ) {
    emit(state.copyWith(searchResults: [], hasSearched: false));
  }
}
