import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';

import 'package:calibre_web_companion/core/exceptions/cancellation_exception.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

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
    on<SendBookByEmail>(_onSendBookByEmail);
    on<OpenBookInReader>(_onOpenBookInReader);
    on<OpenBookInBrowser>(_onOpenBookInBrowser);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
    on<UpdateBookMetadata>(_onUpdateBookMetadata);
    on<SendToEReaderViaBrowser>(_onSendToEReaderViaBrowser);
    on<SendToEReaderByEmail>(_onSendToEReaderByEmail);
    on<CancelSendToEReader>(_onCancelSendToEReader);
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
        event.bookListModel,
        event.bookUuid,
      );

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          isBookRead: event.bookListModel.readStatus,
          isBookArchived: event.bookListModel.isArchived,
          bookDetails: bookDetails,
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
        event.bookListModel,
        event.bookUuid,
      );

      // Check read status
      final isRead = await repository.checkIfBookIsRead(bookDetails.id);

      // Check archive status
      final isArchived = await repository.checkIfBookIsArchived(bookDetails.id);

      emit(
        state.copyWith(
          status: BookDetailsStatus.loaded,
          bookDetails: bookDetails,
          isBookRead: isRead,
          isBookArchived: isArchived,
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
    emit(
      state.copyWith(
        downloadState: DownloadState.downloading,
        downloadProgress: 0,
        downloadErrorMessage: null,
        downloadFilePath: null,
      ),
    );

    _downloadCancelled = false;

    try {
      // Dateiname und Pfad generieren
      final String filePath = await _createPathBasedOnSchema(
        event.directory,
        event.title,
        event.author,
        event.series,
        event.seriesIndex,
        event.format,
        event.schema,
      );

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        emit(
          state.copyWith(
            downloadState: DownloadState.success,
            downloadProgress: 100,
            downloadFilePath: filePath,
          ),
        );
        return;
      }

      // Ensure directory exists
      await Directory(path.dirname(filePath)).create(recursive: true);

      // Create temporary file
      final tempFilePath = '$filePath.downloading';
      final tempFile = File(tempFilePath);

      // Get download stream from repository
      final response = await repository.getDownloadStream(
        event.bookId,
        event.format,
      );

      final contentLength = response.contentLength ?? -1;
      final sink = tempFile.openWrite();
      int receivedBytes = 0;

      try {
        await for (final chunk in response.stream) {
          if (_downloadCancelled) {
            throw const CancellationException('Download cancelled by user');
          }

          receivedBytes += chunk.length;
          sink.add(chunk);

          // Calculate progress and emit updated state
          if (contentLength > 0) {
            final progress = (receivedBytes / contentLength * 100).round();
            emit(state.copyWith(downloadProgress: progress));
          }
        }

        await sink.flush();
        await sink.close();

        // Rename temp file to final file
        if (await tempFile.exists()) {
          await tempFile.rename(filePath);

          emit(
            state.copyWith(
              downloadState: DownloadState.success,
              downloadProgress: 100,
              downloadFilePath: filePath,
            ),
          );
        } else {
          throw Exception('Temporary file was not created correctly');
        }
      } catch (e) {
        await sink.close();

        if (await tempFile.exists()) {
          await tempFile.delete();
        }

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
    } catch (e) {
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
    // State wird durch _onDownloadBook aktualisiert, wenn die Abbruchbedingung erkannt wird
  }

  Future<String> _createPathBasedOnSchema(
    String baseDirectory,
    String title,
    String author,
    String series,
    double seriesIndex,
    String format,
    DownloadSchema schema,
  ) async {
    // Sanitize the file name to prevent invalid characters
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final safeAuthor = author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '$safeTitle.$format';
    String? safeSeries;

    if (series.isNotEmpty) {
      safeSeries = series.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    }

    String filePath;

    switch (schema) {
      case DownloadSchema.flat:
        // Just return the base directory with the file
        filePath = path.join(baseDirectory, fileName);
        break;

      case DownloadSchema.authorOnly:
        // Create author directory
        filePath = path.join(baseDirectory, safeAuthor, fileName);
        break;

      case DownloadSchema.authorBook:
        // Create author/book directory
        filePath = path.join(baseDirectory, safeAuthor, safeTitle, fileName);
        break;

      case DownloadSchema.authorSeriesBook:
        // Create author/series/book directory if series exists
        if (safeSeries != null) {
          filePath = path.join(
            baseDirectory,
            safeAuthor,
            safeSeries,
            safeTitle,
            fileName,
          );
        } else {
          // If no series, fall back to author/book
          filePath = path.join(baseDirectory, safeAuthor, safeTitle, fileName);
        }
        break;
    }

    return filePath;
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
      logger.i('Sending book via email: ${event.bookId}');
      emit(state.copyWith(emailState: EmailState.sending));

      final success = await repository.sendViaEmail(
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
      logger.e('Error sending book via email: $e');
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
      logger.i('Opening book in reader: ${state.bookDetails!.title}');
      emit(state.copyWith(openInReaderState: OpenInReaderState.loading));

      final success = await repository.openInReader(
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
      logger.e('Error opening book in reader: $e');
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
      logger.i('Opening book in browser: ${state.bookDetails!.title}');
      await repository.openInBrowser(state.bookDetails!);
    } catch (e) {
      logger.e('Error opening book in browser: $e');
      // We don't update state for browser opening
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
      // Download book bytes
      emit(state.copyWith(sendToEReaderState: SendToEReaderState.downloading));

      final bookBytes = await repository.downloadBookBytes(
        event.bookId,
        'epub',
      );

      if (_sendToEReaderCancelled) {
        emit(state.copyWith(sendToEReaderState: SendToEReaderState.cancelled));
        return;
      }

      if (bookBytes == null) {
        throw Exception('Failed to download book');
      }

      // Upload to send2ereader
      emit(state.copyWith(sendToEReaderState: SendToEReaderState.uploading));

      final settingsState = GetIt.instance<SettingsBloc>().state;
      final success = await repository.uploadToSend2Ereader(
        settingsState.send2ereaderUrl,
        event.code,
        '${event.title}.epub',
        bookBytes,
        isKindle: event.isKindle,
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
        0, // conversion type
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
}
