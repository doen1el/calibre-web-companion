import 'package:equatable/equatable.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';

abstract class DownloadServiceEvent extends Equatable {
  const DownloadServiceEvent();

  @override
  List<Object?> get props => [];
}

class SearchBooks extends DownloadServiceEvent {
  final String query;
  final DownloadFilterModel? filter;

  const SearchBooks(this.query, {this.filter});

  @override
  List<Object> get props => [query, if (filter != null) filter!];
}

class DownloadBook extends DownloadServiceEvent {
  final String bookId;

  const DownloadBook(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class GetDownloadStatus extends DownloadServiceEvent {}

class ClearSearchResults extends DownloadServiceEvent {}
