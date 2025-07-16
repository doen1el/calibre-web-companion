import 'package:equatable/equatable.dart';

abstract class DownloadServiceEvent extends Equatable {
  const DownloadServiceEvent();

  @override
  List<Object?> get props => [];
}

class SearchBooks extends DownloadServiceEvent {
  final String query;

  const SearchBooks(this.query);

  @override
  List<Object?> get props => [query];
}

class DownloadBook extends DownloadServiceEvent {
  final String bookId;

  const DownloadBook(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class GetDownloadStatus extends DownloadServiceEvent {}

class ClearSearchResults extends DownloadServiceEvent {}
