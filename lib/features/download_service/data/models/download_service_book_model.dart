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
    final extra =
        json['extra'] is Map<String, dynamic>
            ? json['extra'] as Map<String, dynamic>
            : const <String, dynamic>{};

    final topLevelDownloadUrls = _toStringList(json['download_urls']);
    final extraDownloadUrls = _toStringList(extra['download_urls']);
    final fallbackDownloadUrl = _stringOrEmpty(json['download_url']);

    return DownloadServiceBookModel(
      id:
          _stringOrEmpty(json['id']).isNotEmpty
              ? _stringOrEmpty(json['id'])
              : _stringOrEmpty(json['source_id']),
      title: _stringOrEmpty(json['title']),
      author:
          _stringOrEmpty(json['author']).isNotEmpty
              ? _stringOrEmpty(json['author'])
              : _stringOrEmpty(extra['author']),
      format: _stringOrEmpty(json['format']),
      size: _stringOrEmpty(json['size']),
      preview:
          _stringOrEmpty(json['preview']).isNotEmpty
              ? _stringOrEmpty(json['preview'])
              : _stringOrEmpty(extra['preview']),
      publisher:
          _stringOrEmpty(json['publisher']).isNotEmpty
              ? _stringOrEmpty(json['publisher'])
              : _stringOrEmpty(extra['publisher']),
      year:
          _stringOrEmpty(json['year']).isNotEmpty
              ? _stringOrEmpty(json['year'])
              : _stringOrEmpty(extra['year']),
      language:
          _stringOrEmpty(json['language']).isNotEmpty
              ? _stringOrEmpty(json['language'])
              : _stringOrEmpty(extra['language']),
      downloadUrls:
          topLevelDownloadUrls.isNotEmpty
              ? topLevelDownloadUrls
              : extraDownloadUrls.isNotEmpty
              ? extraDownloadUrls
              : fallbackDownloadUrl.isNotEmpty
              ? [fallbackDownloadUrl]
              : const [],
    );
  }

  static String _stringOrEmpty(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
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
