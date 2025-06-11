import 'package:calibre_web_companion/features/book_details/data/models/form_metadata_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookDetailsModel extends BookViewModel {
  final FormatMetadata formatMetadata;
  final List<String> formats;
  final String cover;
  final String thumbnail;
  final Map<String, String> mainFormat;
  final Map<String, String> otherFormats;
  final String titleSort;

  const BookDetailsModel({
    required super.id,
    required super.uuid,
    required super.title,
    required super.authors,
    super.authorSort = '',
    super.comments = '',
    super.data = '',
    super.flags = false,
    super.hasCover = false,
    super.identifiers = '',
    super.isArchived = false,
    super.isbn = '',
    super.languages = '',
    super.lastModified = '',
    super.path = '',
    super.pubdate = '',
    super.publishers = '',
    super.ratings = '',
    super.readStatus = false,
    super.registry = '',
    super.series = '',
    super.seriesIndex = 0.0,
    super.sort = '',
    super.tags = const [],
    super.timestamp = '',
    this.formats = const [],
    this.cover = '',
    this.formatMetadata = const FormatMetadata(formats: {}),
    this.mainFormat = const {},
    this.otherFormats = const {},
    this.thumbnail = '',
    this.titleSort = '',
  });

  @override
  List<Object?> get props => [
    ...super.props,
    formats,
    cover,
    formatMetadata,
    mainFormat,
    otherFormats,
    thumbnail,
    titleSort,
  ];

  factory BookDetailsModel.fromBookListModel(
    BookViewModel bookListModel, [
    Map<String, dynamic> additionalData = const {},
  ]) {
    return BookDetailsModel(
      id: bookListModel.id,
      uuid: bookListModel.uuid,
      title: bookListModel.title,
      authors: bookListModel.authors,
      authorSort: bookListModel.authorSort,
      comments: bookListModel.comments,
      data: bookListModel.data,
      flags: bookListModel.flags,
      hasCover: bookListModel.hasCover,
      identifiers: bookListModel.identifiers,
      isArchived: bookListModel.isArchived,
      isbn: bookListModel.isbn,
      languages: bookListModel.languages,
      lastModified: bookListModel.lastModified,
      path: bookListModel.path,
      pubdate: bookListModel.pubdate,
      publishers: bookListModel.publishers,
      ratings: bookListModel.ratings,
      readStatus: bookListModel.readStatus,
      registry: bookListModel.registry,
      series: bookListModel.series,
      seriesIndex: bookListModel.seriesIndex,
      sort: bookListModel.sort,
      tags: bookListModel.tags,
      timestamp: bookListModel.timestamp,
      formats:
          (additionalData['formats'] as List).map((f) => f.toString()).toList(),
      cover: additionalData['cover'],
      formatMetadata: FormatMetadata.fromJson(additionalData),
      mainFormat: Map<String, String>.from(
        (additionalData['main_format'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      ),
      otherFormats: Map<String, String>.from(
        (additionalData['other_formats'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      ),
      thumbnail: additionalData['thumbnail'] ?? '',
      titleSort: additionalData['title_sort'] ?? '',
    );
  }
}
