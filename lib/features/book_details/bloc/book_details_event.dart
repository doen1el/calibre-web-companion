import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:docman/docman.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

abstract class BookDetailsEvent extends Equatable {
  const BookDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookDetails extends BookDetailsEvent {
  final BookViewModel bookViewModel;
  final String bookUuid;

  const LoadBookDetails(this.bookViewModel, this.bookUuid);

  @override
  List<Object?> get props => [bookUuid];
}

class ReloadBookDetails extends BookDetailsEvent {
  final BookViewModel bookViewModel;
  final String bookUuid;

  const ReloadBookDetails(this.bookViewModel, this.bookUuid);

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
  final String bookId;
  final String format;
  final String title;
  final String author;
  final String series;
  final int seriesIndex;
  final DocumentFile directory;
  final DownloadSchema schema;

  const DownloadBook({
    required this.bookId,
    required this.format,
    required this.title,
    required this.author,
    required this.series,
    required this.seriesIndex,
    required this.directory,
    required this.schema,
  });

  @override
  List<Object?> get props => [
    bookId,
    format,
    title,
    author,
    series,
    seriesIndex,
    directory,
    schema,
  ];
}

class CancelDownload extends BookDetailsEvent {}

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
  final DocumentFile selectedDirectory;
  final DownloadSchema schema;

  const OpenBookInReader({
    required this.selectedDirectory,
    required this.schema,
  });

  @override
  List<Object?> get props => [selectedDirectory, schema];
}

class OpenBookInInternalReader extends BookDetailsEvent {
  final DocumentFile selectedDirectory;
  final DownloadSchema schema;
  final BookDetailsModel book;

  const OpenBookInInternalReader({
    required this.selectedDirectory,
    required this.schema,
    required this.book,
  });

  @override
  List<Object> get props => [selectedDirectory, schema, book];
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

class UpdateBookMetadata extends BookDetailsEvent {
  final String bookId;
  final String title;
  final String authors;
  final String comments;
  final String tags;
  final Uint8List? coverImageBytes;
  final String? coverFileName;
  final BookDetailsModel bookDetails;

  const UpdateBookMetadata({
    required this.bookId,
    required this.title,
    required this.authors,
    required this.comments,
    required this.tags,
    this.coverImageBytes,
    this.coverFileName,
    required this.bookDetails,
  });

  @override
  List<Object?> get props => [
    bookId,
    title,
    authors,
    comments,
    tags,
    coverImageBytes,
    coverFileName,
    bookDetails,
  ];
}

class SendToEReaderViaBrowser extends BookDetailsEvent {
  final String bookId;
  final String code;
  final bool isKindle;
  final String title;
  final String send2ereaderUrl;

  const SendToEReaderViaBrowser({
    required this.bookId,
    required this.code,
    required this.isKindle,
    required this.title,
    required this.send2ereaderUrl,
  });

  @override
  List<Object?> get props => [bookId, code, isKindle, title, send2ereaderUrl];
}

class SendToEReaderByEmail extends BookDetailsEvent {
  final String bookId;
  final String format;

  const SendToEReaderByEmail({required this.bookId, required this.format});

  @override
  List<Object?> get props => [bookId, format];
}

class CancelSendToEReader extends BookDetailsEvent {}

class ClearSnackBarStates extends BookDetailsEvent {
  const ClearSnackBarStates();
}

class UpdateSendToEReaderProgress extends BookDetailsEvent {
  final int progress;
  const UpdateSendToEReaderProgress(this.progress);
}

class OpenSeries extends BookDetailsEvent {
  final String seriesName;

  const OpenSeries(this.seriesName);

  @override
  List<Object> get props => [seriesName];
}
