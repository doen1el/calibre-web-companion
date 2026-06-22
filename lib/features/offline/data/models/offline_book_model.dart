class OfflineBookModel {
  final String uuid;
  final int id;
  final String title;
  final String authors;
  final String series;
  final int seriesIndex;

  final String filePath;
  final String format;

  final String? coverPath;

  final int savedAt;

  const OfflineBookModel({
    required this.uuid,
    required this.id,
    required this.title,
    required this.authors,
    required this.series,
    required this.seriesIndex,
    required this.filePath,
    required this.format,
    required this.savedAt,
    this.coverPath,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'id': id,
    'title': title,
    'authors': authors,
    'series': series,
    'seriesIndex': seriesIndex,
    'filePath': filePath,
    'format': format,
    'coverPath': coverPath,
    'savedAt': savedAt,
  };

  factory OfflineBookModel.fromJson(Map<String, dynamic> json) {
    return OfflineBookModel(
      uuid: json['uuid']?.toString() ?? '',
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      authors: json['authors']?.toString() ?? '',
      series: json['series']?.toString() ?? '',
      seriesIndex: (json['seriesIndex'] as num?)?.toInt() ?? 0,
      filePath: json['filePath']?.toString() ?? '',
      format: json['format']?.toString() ?? 'epub',
      coverPath: json['coverPath']?.toString(),
      savedAt: (json['savedAt'] as num?)?.toInt() ?? 0,
    );
  }

  OfflineBookModel copyWith({String? coverPath}) => OfflineBookModel(
    uuid: uuid,
    id: id,
    title: title,
    authors: authors,
    series: series,
    seriesIndex: seriesIndex,
    filePath: filePath,
    format: format,
    savedAt: savedAt,
    coverPath: coverPath ?? this.coverPath,
  );
}
