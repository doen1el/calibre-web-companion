class DownloadFilterModel {
  static const List<String> allFormats = [
    'epub',
    'mobi',
    'azw3',
    'pdf',
    'fb2',
    'cbz',
    'cbr',
    'djvu',
  ];

  final String? isbn;
  final String? author;
  final String? title;
  final List<String> languages;
  final String? content;
  final List<String> formats;

  const DownloadFilterModel({
    this.isbn,
    this.author,
    this.title,
    this.languages = const ['de'],
    this.content,
    this.formats = allFormats,
  });

  DownloadFilterModel copyWith({
    String? isbn,
    String? author,
    String? title,
    List<String>? languages,
    String? content,
    List<String>? formats,
  }) {
    return DownloadFilterModel(
      isbn: isbn ?? this.isbn,
      author: author ?? this.author,
      title: title ?? this.title,
      languages: languages ?? this.languages,
      content: content ?? this.content,
      formats: formats ?? this.formats,
    );
  }

  bool get hasActiveFilters {
    final formatsChanged = formats.length != allFormats.length;

    return (isbn != null && isbn!.isNotEmpty) ||
        (author != null && author!.isNotEmpty) ||
        (title != null && title!.isNotEmpty) ||
        (content != null && content!.isNotEmpty) ||
        formatsChanged ||
        (languages.length != 1 || languages.first != 'de');
  }
}
