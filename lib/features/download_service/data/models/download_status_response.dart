import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';

class DownloadStatusResponse {
  final Map<String, dynamic> available;
  final Map<String, dynamic> done;
  final Map<String, dynamic> downloading;
  final Map<String, dynamic> error;
  final Map<String, dynamic> queued;
  final Map<String, dynamic> complete;
  final Map<String, dynamic> cancelled;
  final Map<String, dynamic> resolving;

  DownloadStatusResponse({
    required this.available,
    required this.done,
    required this.downloading,
    required this.error,
    required this.queued,
    required this.complete,
    required this.cancelled,
    required this.resolving,
  });

  factory DownloadStatusResponse.fromJson(Map<String, dynamic> json) {
    return DownloadStatusResponse(
      available: json['available'] ?? {},
      done: json['done'] ?? {},
      downloading: json['downloading'] ?? {},
      error: json['error'] ?? {},
      queued: json['queued'] ?? {},
      complete: json['complete'] ?? {},
      cancelled: json['cancelled'] ?? {},
      resolving: json['resolving'] ?? {},
    );
  }

  List<DownloadServiceBookModel> getAllBooks() {
    final List<DownloadServiceBookModel> allBooks = [];

    available.forEach((id, bookData) {
      allBooks.add(
        _createBookFromData(id, bookData, DownloaderStatus.available),
      );
    });

    done.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.done));
    });

    downloading.forEach((id, bookData) {
      allBooks.add(
        _createBookFromData(id, bookData, DownloaderStatus.downloading),
      );
    });

    error.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.error));
    });

    queued.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.queued));
    });


    complete.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.done));
    });

    cancelled.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.error));
    });

    resolving.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.queued));
    });

    return allBooks;
  }

  DownloadServiceBookModel _createBookFromData(
    String id,
    dynamic data,
    DownloaderStatus status,
  ) {
    if (data is! Map<String, dynamic>) {
      return DownloadServiceBookModel(
        id: id,
        title: 'Unknown',
        author: 'Unknown',
        format: 'Unknown',
        size: 'Unknown',
        preview: '',
        publisher: 'Unknown',
        year: '',
        language: 'Unknown',
        status: status,
      );
    }

    return DownloadServiceBookModel(
      id: id,
      title: data['title'] ?? 'Unknown Title',
      author: data['author'] ?? 'Unknown Author',
      format: data['format'] ?? 'Unknown Format',
      size: data['size'] ?? 'Unknown Size',
      preview: data['preview'] ?? '',
      publisher: data['publisher'] ?? 'Unknown Publisher',
      year: data['year'] ?? 'Unknown Year',
      language: data['language'] ?? 'Unknown',
      status: status,
      downloadUrls:
          data['download_urls'] != null
              ? List<String>.from(data['download_urls'])
              : [],
      errorMessage:
          status == DownloaderStatus.error
              ? data['error_message']?.toString()
              : null,
    );
  }
}
