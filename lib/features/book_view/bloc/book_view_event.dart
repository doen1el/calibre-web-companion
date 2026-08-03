import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class BookViewEvent extends Equatable {
  const BookViewEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooks extends BookViewEvent {
  const LoadBooks();
}

class LoadMoreBooks extends BookViewEvent {
  const LoadMoreBooks();
}

class RefreshBooks extends BookViewEvent {
  const RefreshBooks();
}

class ChangeSort extends BookViewEvent {
  final String sortBy;
  final String sortOrder;

  const ChangeSort({required this.sortBy, required this.sortOrder});

  @override
  List<Object?> get props => [sortBy, sortOrder];
}

class SearchBooks extends BookViewEvent {
  final String? query;

  const SearchBooks(this.query);

  @override
  List<Object?> get props => [query];
}

class UploadBook extends BookViewEvent {
  final File book;

  /// Name as reported by the file picker: some Android document providers
  /// hand out a cache path without the original extension
  final String? fileName;

  const UploadBook(this.book, {this.fileName});

  @override
  List<Object?> get props => [book, fileName];
}

class ChangeColumnCount extends BookViewEvent {
  final int count;

  const ChangeColumnCount(this.count);

  @override
  List<Object?> get props => [count];
}

class SetViewMode extends BookViewEvent {
  final bool isListView;

  const SetViewMode(this.isListView);

  @override
  List<Object?> get props => [isListView];
}

class EnterSeriesFolderMode extends BookViewEvent {
  const EnterSeriesFolderMode();
}

class LoadViewSettings extends BookViewEvent {
  const LoadViewSettings();
}

class ChangeLibrary extends BookViewEvent {
  final String libraryId;

  const ChangeLibrary(this.libraryId);

  @override
  List<Object?> get props => [libraryId];
}

class UploadCancel extends BookViewEvent {
  const UploadCancel();
}

class ResetUploadStatus extends BookViewEvent {
  const ResetUploadStatus();
}
