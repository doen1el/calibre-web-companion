import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';

class DownloadServiceBookModel extends Equatable {
  final String id;
  final String title;
  final String author;
  final String format;
  final String size;
  final String preview;
  final String publisher;
  final String year;
  final String language;
  final DownloaderStatus status;
  final List<String> downloadUrls;
  final String? errorMessage;

  const DownloadServiceBookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.size,
    required this.preview,
    required this.publisher,
    required this.year,
    required this.language,
    this.status = DownloaderStatus.notDownloaded,
    this.downloadUrls = const [],
    this.errorMessage,
  });

  factory DownloadServiceBookModel.fromSearchResponse(
    Map<String, dynamic> json,
  ) {
    return DownloadServiceBookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      format: json['format'] ?? '',
      size: json['size'] ?? '',
      preview: json['preview'] ?? '',
      publisher: json['publisher'] ?? '',
      year: json['year']?.toString() ?? '',
      language: json['language'] ?? '',
      downloadUrls: json['download_urls'] != null 
          ? List<String>.from(json['download_urls']) 
          : [],
    );
  }

  DownloadServiceBookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? format,
    String? size,
    String? preview,
    String? publisher,
    String? year,
    String? language,
    DownloaderStatus? status,
    List<String>? downloadUrls,
    String? errorMessage,
  }) {
    return DownloadServiceBookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format ?? this.format,
      size: size ?? this.size,
      preview: preview ?? this.preview,
      publisher: publisher ?? this.publisher,
      year: year ?? this.year,
      language: language ?? this.language,
      status: status ?? this.status,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    format,
    size,
    preview,
    publisher,
    year,
    language,
    status,
    downloadUrls,
    errorMessage,
  ];
}
