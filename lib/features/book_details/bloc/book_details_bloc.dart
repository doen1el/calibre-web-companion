import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';

import 'package:calibre_web_companion/core/exceptions/cancellation_exception.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';

class BookDetailsBloc extends Bloc<BookDetailsEvent, BookDetailsState> {
  final BookDetailsRepository repository;
  final Logger logger;

  BookDetailsBloc({required this.repository, required this.logger})
    : super(const BookDetailsState()) {
    on<LoadBookDetails>(_onLoadBookDetails);
    on<ReloadBookDetails>(_onReloadBookDetails);
    on<ToggleReadStatus>(_onToggleReadStatus);
    on<ToggleArchiveStatus>(_onToggleArchiveStatus);
    on<DownloadBook>(_onDownloadBook);
    on<CancelDownload>(_onCancelDownload);
    on<OpenBookInReader>(_onOpenBookInReader);
    on<OpenBookInBrowser>(_onOpenBookInBrowser);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
    on<UpdateBookMetadata>(_onUpdateBookMetadata);
    on<SendToEReaderViaBrowser>(_onSendToEReaderViaBrowser);
    on<SendToEReaderByEmail>(_onSendToEReaderByEmail);
    on<CancelSendToEReader>(_onCancelSendToEReader);
    on<ClearSnackBarStates>(_onClearSnackBarStates);
    on<OpenBookInInternalReader>(_openBookInInternalReader);
    on<UpdateSendToEReaderProgress>((event, emit) {
      emit(state.copyWith(sendToEReaderProgress: event.progress));
    });
    on<OpenSeries>(_onOpenSeries);
  }

  bool _downloadCancelled = false;
  bool _sendToEReaderCancelled = false;

  Future<void> _onLoadBookDetails(
    LoadBookDetails event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      logger.i('Loading book details: ${event.bookUuid}');
      emit(
        state.copyWith(status: BookDetailsStatus.loading, errorMessage: null),
      );

      final bookDetails = await repository.getBookDetails(
        event.bookViewModel,
        event.bookUuid,
      );

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          isBookRead: event.bookViewModel.readStatus,
          isBookArchived: event.bookViewModel.isArchived,
          bookDetails: bookDetails,
          bookViewModel: event.bookViewModel,
        ),
      );
    } catch (e) {
      logger.e('Error loading book details: $e');
      emit(
        state.copyWith(
          status: BookDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearSnackBarStates(
    ClearSnackBarStates event,
    Emitter<BookDetailsState> emit,
  ) {
    emit(
      state.copyWith(
        openInReaderState: OpenInReaderState.initial,
        downloadState: DownloadState.initial,
        sendToEReaderState: SendToEReaderState.initial,
        metadataUpdateState: MetadataUpdateState.initial,
        readStatusState: ReadStatusState.initial,
        archiveStatusState: ArchiveStatusState.initial,
      ),
    );
  }

  Future<void> _onReloadBookDetails(
    ReloadBookDetails event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      logger.i('Reloading book details: ${event.bookUuid}');
      emit(
        state.copyWith(status: BookDetailsStatus.loading, errorMessage: null),
      );

      final bookDetails = await repository.getBookDetails(
        event.bookViewModel,
        event.bookUuid,
      );

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          bookDetails: bookDetails,
          isBookRead: event.bookViewModel.readStatus,
          isBookArchived: event.bookViewModel.isArchived,
        ),
      );
    } catch (e) {
      logger.e('Error reloading book details: $e');
      emit(
        state.copyWith(
          status: BookDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleReadStatus(
    ToggleReadStatus event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      logger.i('Toggling read status: ${event.bookId}');
      emit(state.copyWith(readStatusState: ReadStatusState.loading));

      final success = await repository.toggleReadStatus(event.bookId);

      if (success) {
        emit(
          state.copyWith(
            readStatusState: ReadStatusState.success,
            isBookRead: !state.isBookRead,
          ),
        );
      } else {
        emit(
          state.copyWith(
            readStatusState: ReadStatusState.error,
            errorMessage: 'Failed to toggle read status',
          ),
        );
      }
    } catch (e) {
      logger.e('Error toggling read status: $e');
      emit(
        state.copyWith(
          readStatusState: ReadStatusState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleArchiveStatus(
    ToggleArchiveStatus event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      logger.i('Toggling archive status: ${event.bookId}');
      emit(state.copyWith(archiveStatusState: ArchiveStatusState.loading));

      final success = await repository.toggleArchiveStatus(event.bookId);

      if (success) {
        emit(
          state.copyWith(
            archiveStatusState: ArchiveStatusState.success,
            isBookArchived: !state.isBookArchived,
          ),
        );
      } else {
        emit(
          state.copyWith(
            archiveStatusState: ArchiveStatusState.error,
            errorMessage: 'Failed to toggle archive status',
          ),
        );
      }
    } catch (e) {
      logger.e('Error toggling archive status: $e');
      emit(
        state.copyWith(
          archiveStatusState: ArchiveStatusState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDownloadBook(
    DownloadBook event,
    Emitter<BookDetailsState> emit,
  ) async {
    logger.i(
      'Starting download for book ${event.bookId}, format: ${event.format}',
    );

    emit(
      state.copyWith(
        downloadState: DownloadState.downloading,
        downloadProgress: 0,
        downloadErrorMessage: null,
      ),
    );

    _downloadCancelled = false;

    try {
      if (state.bookDetails == null) {
        throw Exception('Book details not available');
      }

      final schema = event.schema;

      final filePath = await repository.downloadBook(
        state.bookDetails!,
        event.directory,
        schema,
        format: event.format,
        progressCallback: (progress) {
          if (_downloadCancelled) {
            throw const CancellationException('Download cancelled by user');
          }
          emit(state.copyWith(downloadProgress: progress));
        },
      );

      logger.i('Download completed successfully: $filePath');
      emit(
        state.copyWith(
          downloadState: DownloadState.success,
          downloadProgress: 100,
          downloadFilePath: filePath,
        ),
      );
    } catch (e) {
      logger.e('Error in download process: $e');
      if (e is CancellationException) {
        emit(
          state.copyWith(
            downloadState: DownloadState.canceled,
            downloadErrorMessage: e.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            downloadState: DownloadState.failed,
            downloadErrorMessage: e.toString(),
          ),
        );
      }
    }
  }

  void _onCancelDownload(CancelDownload event, Emitter<BookDetailsState> emit) {
    _downloadCancelled = true;

    emit(state.copyWith(downloadState: DownloadState.canceled));
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<BookDetailsState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));
  }

  Future<void> _onOpenBookInReader(
    OpenBookInReader event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state.bookDetails == null) {
      emit(
        state.copyWith(
          openInReaderState: OpenInReaderState.error,
          errorMessage: 'Book details not available',
        ),
      );
      return;
    }

    try {
      logger.i('Opening book in reader: ${state.bookDetails!.title}');
      emit(
        state.copyWith(
          openInReaderState: OpenInReaderState.loading,
          downloadProgress: 0,
        ),
      );

      final success = await repository.openInReader(
        state.bookDetails!,
        event.selectedDirectory,
        event.schema,
        progressCallback: (progress) {
          logger.d('Reader download progress: $progress%');
          emit(state.copyWith(downloadProgress: progress));
        },
      );

      if (success) {
        emit(
          state.copyWith(
            openInReaderState: OpenInReaderState.success,
            downloadProgress: 100,
          ),
        );
      } else {
        emit(
          state.copyWith(
            openInReaderState: OpenInReaderState.error,
            errorMessage: 'Failed to open book in reader',
          ),
        );
      }
    } catch (e) {
      logger.e('Error opening book in reader: $e');
      emit(
        state.copyWith(
          openInReaderState: OpenInReaderState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _openBookInInternalReader(
    OpenBookInInternalReader event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state.bookDetails == null) {
      emit(
        state.copyWith(
          openInInternalReaderState: OpenInInternalReaderState.error,
          errorMessage: 'Book details not available',
        ),
      );
      return;
    }

    try {
      logger.i('Opening book in internal reader: ${state.bookDetails!.title}');
      emit(
        state.copyWith(
          openInInternalReaderState: OpenInInternalReaderState.loading,
        ),
      );

      final downloadedPath = await repository.openInInternalReader(
        event.selectedDirectory,
        event.schema,
        event.book,
        progressCallback: (progress) {
          logger.d('Reader download progress: $progress%');
          emit(state.copyWith(downloadProgress: progress));
        },
      );

      if (downloadedPath.isNotEmpty) {
        emit(
          state.copyWith(
            openInInternalReaderState: OpenInInternalReaderState.success,
            downloadFilePath: downloadedPath,
          ),
        );
      } else {
        emit(
          state.copyWith(
            openInInternalReaderState: OpenInInternalReaderState.error,
            errorMessage: 'Failed to open book in internal reader',
          ),
        );
      }
    } catch (e) {
      logger.e('Error opening book in internal reader: $e');
      emit(
        state.copyWith(
          openInInternalReaderState: OpenInInternalReaderState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onOpenBookInBrowser(
    OpenBookInBrowser event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state.bookDetails == null) {
      return;
    }

    try {
      logger.i('Opening book in browser: ${state.bookDetails!.title}');
      await repository.openInBrowser(state.bookDetails!);
    } catch (e) {
      logger.e('Error opening book in browser: $e');
    }
  }

  Future<void> _onUpdateBookMetadata(
    UpdateBookMetadata event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(state.copyWith(metadataUpdateState: MetadataUpdateState.loading));

    try {
      final result = await repository.updateBookMetadata(
        event.bookId,
        title: event.title,
        authors: event.authors,
        comments: event.comments,
        tags: event.tags,
        coverImageBytes: event.coverImageBytes,
        coverFileName: event.coverFileName,
      );

      if (result) {
        emit(state.copyWith(metadataUpdateState: MetadataUpdateState.success));
      } else {
        emit(
          state.copyWith(
            metadataUpdateState: MetadataUpdateState.error,
            errorMessage: 'Update failed',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          metadataUpdateState: MetadataUpdateState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSendToEReaderViaBrowser(
    SendToEReaderViaBrowser event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        sendToEReaderState: SendToEReaderState.loading,
        sendToEReaderProgress: 0,
      ),
    );

    _sendToEReaderCancelled = false;

    try {
      emit(state.copyWith(sendToEReaderState: SendToEReaderState.downloading));

      final List<int> bookBytes = [];
      final response = await repository.getDownloadStream(event.bookId, 'epub');

      var contentLength = response.contentLength ?? -1;
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        if (_sendToEReaderCancelled) {
          emit(
            state.copyWith(sendToEReaderState: SendToEReaderState.cancelled),
          );
          return;
        }

        receivedBytes += chunk.length;
        bookBytes.addAll(chunk);

        if (contentLength > 0) {
          final progress = (receivedBytes / contentLength * 100).round();
          logger.d('Download progress: $progress%');
          emit(state.copyWith(sendToEReaderProgress: progress));
        }
      }

      if (_sendToEReaderCancelled) {
        emit(state.copyWith(sendToEReaderState: SendToEReaderState.cancelled));
        return;
      }

      if (bookBytes.isEmpty) {
        throw Exception('Failed to download book');
      }

      emit(
        state.copyWith(
          sendToEReaderState: SendToEReaderState.uploading,
          sendToEReaderProgress: 0,
        ),
      );

      logger.i(
        'Uploading book to Send2Ereader: ${event.title}, URL: ${event.send2ereaderUrl}',
      );

      final success = await repository.uploadToSend2Ereader(
        event.send2ereaderUrl,
        event.code,
        '${event.title}.epub',
        bookBytes,
        isKindle: event.isKindle,
        onProgressUpdate: (progress) {
          if (!_sendToEReaderCancelled) {
            logger.d('Upload progress: $progress%');
            add(UpdateSendToEReaderProgress(progress));
          }
        },
      );

      if (_sendToEReaderCancelled) {
        emit(state.copyWith(sendToEReaderState: SendToEReaderState.cancelled));
        return;
      }

      emit(
        state.copyWith(
          sendToEReaderState:
              success ? SendToEReaderState.success : SendToEReaderState.error,
        ),
      );
    } catch (e) {
      if (_sendToEReaderCancelled) {
        emit(state.copyWith(sendToEReaderState: SendToEReaderState.cancelled));
      } else {
        emit(
          state.copyWith(
            sendToEReaderState: SendToEReaderState.error,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onSendToEReaderByEmail(
    SendToEReaderByEmail event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        sendToEReaderState: SendToEReaderState.loading,
        sendToEReaderProgress: 0,
      ),
    );

    try {
      emit(state.copyWith(sendToEReaderState: SendToEReaderState.uploading));

      final success = await repository.sendBookViaEmail(
        event.bookId,
        event.format,
        0,
      );

      emit(
        state.copyWith(
          sendToEReaderState:
              success ? SendToEReaderState.success : SendToEReaderState.error,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sendToEReaderState: SendToEReaderState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onCancelSendToEReader(
    CancelSendToEReader event,
    Emitter<BookDetailsState> emit,
  ) {
    _sendToEReaderCancelled = true;
  }

  Future<void> _onOpenSeries(
    OpenSeries event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(
      state.copyWith(seriesNavigationStatus: SeriesNavigationStatus.loading),
    );

    final path = await repository.getSeriesPath(event.seriesName);

    if (path != null) {
      emit(
        state.copyWith(
          seriesNavigationStatus: SeriesNavigationStatus.success,
          seriesNavigationPath: path,
        ),
      );
      emit(
        state.copyWith(
          seriesNavigationStatus: SeriesNavigationStatus.initial,
          seriesNavigationPath: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          seriesNavigationStatus: SeriesNavigationStatus.error,
          errorMessage: 'Series not found',
        ),
      );
      emit(
        state.copyWith(seriesNavigationStatus: SeriesNavigationStatus.initial),
      );
    }
  }
}
