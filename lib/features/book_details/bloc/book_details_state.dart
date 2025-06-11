import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';

enum BookDetailsStatus { initial, loading, loaded, error }

enum ReadStatusState { initial, loading, success, error }

enum ArchiveStatusState { initial, loading, success, error }

enum DownloadState {
  initial,
  selectingDestination,
  downloading,
  success,
  error,
}

enum EmailState { initial, sending, success, error }

enum OpenInReaderState { initial, loading, success, error }

class BookDetailsState extends Equatable {
  final BookDetailsStatus status;
  final BookDetailsModel? bookDetails;
  final String? errorMessage;
  final bool isBookRead;
  final ReadStatusState readStatusState;
  final bool isBookArchived;
  final ArchiveStatusState archiveStatusState;
  final DownloadState downloadState;
  final int downloadProgress;
  final String? downloadedFilePath;
  final EmailState emailState;
  final OpenInReaderState openInReaderState;

  const BookDetailsState({
    this.status = BookDetailsStatus.initial,
    this.bookDetails,
    this.errorMessage,
    this.isBookRead = false,
    this.readStatusState = ReadStatusState.initial,
    this.isBookArchived = false,
    this.archiveStatusState = ArchiveStatusState.initial,
    this.downloadState = DownloadState.initial,
    this.downloadProgress = 0,
    this.downloadedFilePath,
    this.emailState = EmailState.initial,
    this.openInReaderState = OpenInReaderState.initial,
  });

  BookDetailsState copyWith({
    BookDetailsStatus? status,
    BookDetailsModel? bookDetails,
    String? errorMessage,
    bool? isBookRead,
    ReadStatusState? readStatusState,
    bool? isBookArchived,
    ArchiveStatusState? archiveStatusState,
    DownloadState? downloadState,
    int? downloadProgress,
    String? downloadedFilePath,
    EmailState? emailState,
    OpenInReaderState? openInReaderState,
  }) {
    return BookDetailsState(
      status: status ?? this.status,
      bookDetails: bookDetails ?? this.bookDetails,
      errorMessage: errorMessage,
      isBookRead: isBookRead ?? this.isBookRead,
      readStatusState: readStatusState ?? this.readStatusState,
      isBookArchived: isBookArchived ?? this.isBookArchived,
      archiveStatusState: archiveStatusState ?? this.archiveStatusState,
      downloadState: downloadState ?? this.downloadState,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      emailState: emailState ?? this.emailState,
      openInReaderState: openInReaderState ?? this.openInReaderState,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bookDetails,
    errorMessage,
    isBookRead,
    readStatusState,
    isBookArchived,
    archiveStatusState,
    downloadState,
    downloadProgress,
    downloadedFilePath,
    emailState,
    openInReaderState,
  ];
}
