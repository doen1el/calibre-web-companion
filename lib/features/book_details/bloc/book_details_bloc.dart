import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'book_details_event.dart';
import 'book_details_state.dart';

class BookDetailsBloc extends Bloc<BookDetailsEvent, BookDetailsState> {
  final BookDetailsRepository _repository;
  final Logger _logger;

  BookDetailsBloc({required BookDetailsRepository repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger(),
      super(const BookDetailsState()) {
    on<LoadBookDetails>(_onLoadBookDetails);
    on<ReloadBookDetails>(_onReloadBookDetails);
    on<ToggleReadStatus>(_onToggleReadStatus);
    on<ToggleArchiveStatus>(_onToggleArchiveStatus);
    on<DownloadBook>(_onDownloadBook);
    on<SendBookByEmail>(_onSendBookByEmail);
    on<OpenBookInReader>(_onOpenBookInReader);
    on<OpenBookInBrowser>(_onOpenBookInBrowser);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
  }

  Future<void> _onLoadBookDetails(
    LoadBookDetails event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      _logger.i('Loading book details: ${event.bookUuid}');
      emit(
        state.copyWith(status: BookDetailsStatus.loading, errorMessage: null),
      );

      final bookDetails = await _repository.getBookDetails(
        event.bookListModel,
        event.bookUuid,
      );

      // Check read status
      final isRead = await _repository.checkIfBookIsRead(bookDetails.id);

      // Check archive status
      final isArchived = await _repository.checkIfBookIsArchived(
        bookDetails.id,
      );

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          bookDetails: bookDetails,
          isBookRead: isRead,
          isBookArchived: isArchived,
        ),
      );
    } catch (e) {
      _logger.e('Error loading book details: $e');
      emit(
        state.copyWith(
          status: BookDetailsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onReloadBookDetails(
    ReloadBookDetails event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      _logger.i('Reloading book details: ${event.bookUuid}');
      emit(
        state.copyWith(status: BookDetailsStatus.loading, errorMessage: null),
      );

      final bookDetails = await _repository.getBookDetails(
        event.bookListModel,
        event.bookUuid,
      );

      // Check read status
      final isRead = await _repository.checkIfBookIsRead(bookDetails.id);

      // Check archive status
      final isArchived = await _repository.checkIfBookIsArchived(
        bookDetails.id,
      );

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          bookDetails: bookDetails,
          isBookRead: isRead,
          isBookArchived: isArchived,
        ),
      );
    } catch (e) {
      _logger.e('Error reloading book details: $e');
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
      _logger.i('Toggling read status: ${event.bookId}');
      emit(state.copyWith(readStatusState: ReadStatusState.loading));

      final success = await _repository.toggleReadStatus(event.bookId);

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
      _logger.e('Error toggling read status: $e');
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
      _logger.i('Toggling archive status: ${event.bookId}');
      emit(state.copyWith(archiveStatusState: ArchiveStatusState.loading));

      final success = await _repository.toggleArchiveStatus(event.bookId);

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
      _logger.e('Error toggling archive status: $e');
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
    if (state.bookDetails == null) {
      emit(
        state.copyWith(
          downloadState: DownloadState.error,
          errorMessage: 'Book details not available',
        ),
      );
      return;
    }

    try {
      _logger.i(
        'Downloading book: ${state.bookDetails!.title} in ${event.format} format',
      );
      emit(
        state.copyWith(
          downloadState: DownloadState.downloading,
          downloadProgress: 0,
        ),
      );

      final filePath = await _repository.downloadBook(
        state.bookDetails!,
        event.selectedDirectory,
        event.schema,
        format: event.format,
        progressCallback: (progress) {
          add(UpdateDownloadProgress(progress));
        },
      );

      emit(
        state.copyWith(
          downloadState: DownloadState.success,
          downloadedFilePath: filePath,
        ),
      );
    } catch (e) {
      _logger.e('Error downloading book: $e');
      emit(
        state.copyWith(
          downloadState: DownloadState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<BookDetailsState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));
  }

  Future<void> _onSendBookByEmail(
    SendBookByEmail event,
    Emitter<BookDetailsState> emit,
  ) async {
    try {
      _logger.i('Sending book via email: ${event.bookId}');
      emit(state.copyWith(emailState: EmailState.sending));

      final success = await _repository.sendViaEmail(
        event.bookId,
        event.format,
        event.conversion,
      );

      if (success) {
        emit(state.copyWith(emailState: EmailState.success));
      } else {
        emit(
          state.copyWith(
            emailState: EmailState.error,
            errorMessage: 'Failed to send book via email',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error sending book via email: $e');
      emit(
        state.copyWith(
          emailState: EmailState.error,
          errorMessage: e.toString(),
        ),
      );
    }
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
      _logger.i('Opening book in reader: ${state.bookDetails!.title}');
      emit(state.copyWith(openInReaderState: OpenInReaderState.loading));

      final success = await _repository.openInReader(
        state.bookDetails!,
        event.selectedDirectory,
        event.schema,
      );

      if (success) {
        emit(state.copyWith(openInReaderState: OpenInReaderState.success));
      } else {
        emit(
          state.copyWith(
            openInReaderState: OpenInReaderState.error,
            errorMessage: 'Failed to open book in reader',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error opening book in reader: $e');
      emit(
        state.copyWith(
          openInReaderState: OpenInReaderState.error,
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
      _logger.i('Opening book in browser: ${state.bookDetails!.title}');
      await _repository.openInBrowser(state.bookDetails!);
    } catch (e) {
      _logger.e('Error opening book in browser: $e');
      // We don't update state for browser opening
    }
  }
}
