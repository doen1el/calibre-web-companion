import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';

enum DownloadServiceTab { search, downloads }

enum DownloadServiceStatus { initial, loading, loaded, error }

class DownloadServiceState extends Equatable {
  final DownloadServiceStatus searchStatus;
  final DownloadServiceStatus downloadStatus;
  final DownloadServiceStatus statusLoadingStatus;
  final List<DownloadServiceBookModel> searchResults;
  final List<DownloadServiceBookModel> books;
  final String? downloadingBookId;
  final bool hasSearched;
  final String? errorMessage;
  final DownloadServiceTab activeTab;

  const DownloadServiceState({
    this.searchStatus = DownloadServiceStatus.initial,
    this.downloadStatus = DownloadServiceStatus.initial,
    this.statusLoadingStatus = DownloadServiceStatus.initial,
    this.searchResults = const [],
    this.books = const [],
    this.downloadingBookId,
    this.hasSearched = false,
    this.errorMessage,
    this.activeTab = DownloadServiceTab.search,
  });

  bool get isSearching => searchStatus == DownloadServiceStatus.loading;
  bool get isLoading => statusLoadingStatus == DownloadServiceStatus.loading;
  bool get isDownloading => downloadingBookId != null;

  bool isBookDownloading(String bookId) => downloadingBookId == bookId;

  DownloadServiceState copyWith({
    DownloadServiceStatus? searchStatus,
    DownloadServiceStatus? downloadStatus,
    DownloadServiceStatus? statusLoadingStatus,
    List<DownloadServiceBookModel>? searchResults,
    List<DownloadServiceBookModel>? books,
    String? downloadingBookId,
    bool? hasSearched,
    String? errorMessage,
    DownloadServiceTab? activeTab,
  }) {
    return DownloadServiceState(
      searchStatus: searchStatus ?? this.searchStatus,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      statusLoadingStatus: statusLoadingStatus ?? this.statusLoadingStatus,
      searchResults: searchResults ?? this.searchResults,
      books: books ?? this.books,
      downloadingBookId: downloadingBookId,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [
    searchStatus,
    downloadStatus,
    statusLoadingStatus,
    searchResults,
    books,
    downloadingBookId,
    hasSearched,
    errorMessage,
    activeTab,
  ];
}
