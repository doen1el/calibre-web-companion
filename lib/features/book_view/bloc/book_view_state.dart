import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

enum UploadStatus { initial, loading, uploading, success, failed }

class BookViewState extends Equatable {
  final List<BookViewModel> books;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final bool hasMoreBooks;
  final int offset;
  final int limit;
  final String sortBy;
  final String sortOrder;
  final String? searchQuery;
  final int columnCount;
  final bool isListView;
  final UploadStatus uploadStatus;
  final bool isOpds;

  const BookViewState({
    this.books = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.hasMoreBooks = true,
    this.offset = 0,
    this.limit = 20,
    this.sortBy = '',
    this.sortOrder = '',
    this.searchQuery,
    this.columnCount = 2,
    this.isListView = false,
    this.uploadStatus = UploadStatus.initial,
    this.isOpds = false,
  });

  BookViewState copyWith({
    List<BookViewModel>? books,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMoreBooks,
    int? offset,
    int? limit,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
    int? columnCount,
    bool? isListView,
    UploadStatus? uploadStatus,
    bool? isOpds,
  }) {
    return BookViewState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMoreBooks: hasMoreBooks ?? this.hasMoreBooks,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      columnCount: columnCount ?? this.columnCount,
      isListView: isListView ?? this.isListView,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isOpds: isOpds ?? this.isOpds,
    );
  }

  @override
  List<Object?> get props => [
    books,
    isLoading,
    hasError,
    errorMessage,
    hasMoreBooks,
    offset,
    limit,
    sortBy,
    sortOrder,
    searchQuery,
    columnCount,
    isListView,
    uploadStatus,
    isOpds,
  ];
}
