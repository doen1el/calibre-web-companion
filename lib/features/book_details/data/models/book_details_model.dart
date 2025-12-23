import 'package:calibre_web_companion/core/services/tag_service.dart';
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
    BookViewModel bookListModel,
    Map<String, dynamic> additionalData,
    TagService tagService,
  ) {
    final List<String> tagNames =
        (additionalData['tags'] as List?)
            ?.map((tag) => tag.toString())
            .toList() ??
        const [];

    final List<TagModel> tagModels = tagService.convertTagsToModels(tagNames);

    return BookDetailsModel(
      id: bookListModel.id,
      uuid: bookListModel.uuid,
      title: additionalData['title'] ?? '',
      authors: (additionalData['authors'] as List)
          .map((f) => f.toString())
          .join(', '),
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
      comments: _removeHtmlTags(additionalData['comments'] ?? ''),
      // TODO: Does not work when updating tags
      tags:
          (additionalData['tags'] as List?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      tagModels: tagModels,
    );
  }

  static String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String parsedString = htmlString.replaceAll(exp, '');

    parsedString = parsedString
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');

    return parsedString.trim();
  }

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

  BookDetailsModel copyWith({
    int? id,
    String? uuid,
    String? title,
    String? authors,
    String? authorSort,
    String? data,
    bool? flags,
    bool? hasCover,
    String? identifiers,
    bool? isArchived,
    String? isbn,
    String? languages,
    String? lastModified,
    String? path,
    String? pubdate,
    String? publishers,
    bool? readStatus,
    String? registry,
    String? series,
    int? seriesIndex,
    String? sort,
    String? timestamp,
    List<String>? formats,
    String? cover,
    FormatMetadata? formatMetadata,
    Map<String, String>? mainFormat,
    Map<String, String>? otherFormats,
    String? thumbnail,
    String? titleSort,
    double? rating,
    String? comments,
    List<String>? tags,
    List<TagModel>? tagModels,
  }) {
    return BookDetailsModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      authorSort: authorSort ?? this.authorSort,
      data: data ?? this.data,
      flags: flags ?? this.flags,
      hasCover: hasCover ?? this.hasCover,
      identifiers: identifiers ?? this.identifiers,
      isArchived: isArchived ?? this.isArchived,
      isbn: isbn ?? this.isbn,
      languages: languages ?? this.languages,
      lastModified: lastModified ?? this.lastModified,
      path: path ?? this.path,
      pubdate: pubdate ?? this.pubdate,
      publishers: publishers ?? this.publishers,
      readStatus: readStatus ?? this.readStatus,
      registry: registry ?? this.registry,
      series: series ?? this.series,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      sort: sort ?? this.sort,
      timestamp: timestamp ?? this.timestamp,
      formats: formats ?? this.formats,
      cover: cover ?? this.cover,
      formatMetadata: formatMetadata ?? this.formatMetadata,
      mainFormat: mainFormat ?? this.mainFormat,
      otherFormats: otherFormats ?? this.otherFormats,
      thumbnail: thumbnail ?? this.thumbnail,
      titleSort: titleSort ?? this.titleSort,
      rating: rating ?? this.rating,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      tagModels: tagModels ?? this.tagModels,
    );
  }
}
