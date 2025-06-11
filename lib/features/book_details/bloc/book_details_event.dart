import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';

abstract class BookDetailsEvent extends Equatable {
  const BookDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookDetails extends BookDetailsEvent {
  final BookViewModel bookListModel;
  final String bookUuid;

  const LoadBookDetails(this.bookListModel, this.bookUuid);

  @override
  List<Object?> get props => [bookUuid];
}

class ReloadBookDetails extends BookDetailsEvent {
  final BookViewModel bookListModel;
  final String bookUuid;

  const ReloadBookDetails(this.bookListModel, this.bookUuid);

  @override
  List<Object?> get props => [bookUuid];
}

class ToggleReadStatus extends BookDetailsEvent {
  final int bookId;

  const ToggleReadStatus(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class ToggleArchiveStatus extends BookDetailsEvent {
  final int bookId;

  const ToggleArchiveStatus(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class DownloadBook extends BookDetailsEvent {
  final String selectedDirectory;
  final DownloadSchema schema;
  final String format;

  const DownloadBook({
    required this.selectedDirectory,
    required this.schema,
    this.format = 'epub',
  });

  @override
  List<Object?> get props => [selectedDirectory, schema, format];
}

class SendBookByEmail extends BookDetailsEvent {
  final String bookId;
  final String format;
  final int conversion;

  const SendBookByEmail({
    required this.bookId,
    required this.format,
    required this.conversion,
  });

  @override
  List<Object?> get props => [bookId, format, conversion];
}

class OpenBookInReader extends BookDetailsEvent {
  final String selectedDirectory;
  final DownloadSchema schema;

  const OpenBookInReader({
    required this.selectedDirectory,
    required this.schema,
  });

  @override
  List<Object?> get props => [selectedDirectory, schema];
}

class OpenBookInBrowser extends BookDetailsEvent {
  const OpenBookInBrowser();
}

class UpdateDownloadProgress extends BookDetailsEvent {
  final int progress;

  const UpdateDownloadProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}
