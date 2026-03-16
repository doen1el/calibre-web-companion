import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';

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
  final DownloadServiceBookModel book;

  const DownloadBook(this.book);

  @override
  List<Object?> get props => [book];
}

class GetDownloadStatus extends DownloadServiceEvent {}

class ClearSearchResults extends DownloadServiceEvent {}

class LoadDownloadConfig extends DownloadServiceEvent {}

class LoadSavedFilter extends DownloadServiceEvent {}

class SaveFilter extends DownloadServiceEvent {
  final DownloadFilterModel filter;
  const SaveFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}
