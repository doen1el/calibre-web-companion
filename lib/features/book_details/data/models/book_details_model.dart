import 'package:calibre_web_companion/features/book_details/data/models/form_metadata_model.dart';
import 'package:calibre_web_companion/features/book_details/data/models/tag_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookDetailsModel extends BookViewModel {
  final FormatMetadata formatMetadata;
  final List<String> formats;
  final String cover;
  final String thumbnail;
  final Map<String, String> mainFormat;
  final Map<String, String> otherFormats;
  final String titleSort;
  final double rating;
  final String comments;
  final List<String> tags;
  final List<TagModel> tagModels;

  const BookDetailsModel({
    required super.id,
    required super.uuid,
    required super.title,
    required super.authors,
    super.authorSort = '',
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
    super.readStatus = false,
    super.registry = '',
    super.series = '',
    super.seriesIndex = 0,
    super.sort = '',
    super.timestamp = '',
    this.formats = const [],
    this.cover = '',
    this.formatMetadata = const FormatMetadata(formats: {}),
    this.mainFormat = const {},
    this.otherFormats = const {},
    this.thumbnail = '',
    this.titleSort = '',
    this.rating = 0.0,
    this.comments = '',
    this.tags = const [],
    this.tagModels = const [],
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
    rating,
    comments,
    tags,
    tagModels,
  ];

  factory BookDetailsModel.fromBookListModel(
    BookViewModel bookListModel, [
    Map<String, dynamic> additionalData = const {},
    List<TagModel>? tagModels,
  ]) {
    return BookDetailsModel(
      id: bookListModel.id,
      uuid: bookListModel.uuid,
      title: bookListModel.title,
      authors: bookListModel.authors,
      authorSort: bookListModel.authorSort,
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
      readStatus: bookListModel.readStatus,
      registry: bookListModel.registry,
      series: bookListModel.series,
      seriesIndex: bookListModel.seriesIndex,
      sort: bookListModel.sort,
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
      rating: double.tryParse(additionalData['rating'].toString()) ?? 0.0,
      comments: additionalData['comments'] ?? '',
      tags:
          (additionalData['tags'] as List?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      tagModels: tagModels ?? [],
    );
  }

  /// Converts the BookDetailsModel to a JSON map
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'formats': formats,
      'cover': cover,
      'format_metadata': formatMetadata.toJson(),
      'main_format': mainFormat,
      'other_formats': otherFormats,
      'thumbnail': thumbnail,
      'title_sort': titleSort,
      'rating': rating,
      'comments': comments,
      'tags': tags,
    };
  }
}
