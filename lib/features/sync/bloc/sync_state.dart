import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';

enum SyncStatus {
  initial,
  idle,
  scanning,
  preview,
  syncing,
  paused,
  completed,
  canceled,
  error,
}

class SyncQueueItem extends Equatable {
  final BookViewModel book;
  final String status;

  const SyncQueueItem({required this.book, this.status = 'pending'});

  SyncQueueItem copyWith({String? status}) {
    return SyncQueueItem(book: book, status: status ?? this.status);
  }

  @override
  List<Object?> get props => [book, status];
}

class SyncState extends Equatable {
  final SyncStatus status;
  final List<SyncQueueItem> queue;
  final int totalBooksToCheck;
  final int syncedCount;
  final String? currentBookTitle;
  final double currentProgress;
  final String? errorMessage;
  final SyncFilter filter;
  final List<BookViewModel> previewBooks;

  const SyncState({
    this.status = SyncStatus.initial,
    this.queue = const [],
    this.totalBooksToCheck = 0,
    this.syncedCount = 0,
    this.currentBookTitle,
    this.currentProgress = 0.0,
    this.errorMessage,
    this.filter = const SyncFilter(),
    this.previewBooks = const [],
  });

  SyncState copyWith({
    SyncStatus? status,
    List<SyncQueueItem>? queue,
    int? totalBooksToCheck,
    int? syncedCount,
    String? currentBookTitle,
    double? currentProgress,
    String? errorMessage,
    SyncFilter? filter,
    List<BookViewModel>? previewBooks,
  }) {
    return SyncState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      totalBooksToCheck: totalBooksToCheck ?? this.totalBooksToCheck,
      syncedCount: syncedCount ?? this.syncedCount,
      currentBookTitle: currentBookTitle ?? this.currentBookTitle,
      currentProgress: currentProgress ?? this.currentProgress,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
      previewBooks: previewBooks ?? this.previewBooks,
    );
  }

  @override
  List<Object?> get props => [
    status,
    queue,
    totalBooksToCheck,
    syncedCount,
    currentBookTitle,
    currentProgress,
    errorMessage,
    filter,
    previewBooks,
  ];
}
