class DownloadConfigModel {
  final List<String> supportedFormats;
  final List<Map<String, String>> languages;
  final List<String> defaultLanguage;

  const DownloadConfigModel({
    this.supportedFormats = const [],
    this.languages = const [],
    this.defaultLanguage = const ['en'],
  });

  factory DownloadConfigModel.fromJson(Map<String, dynamic> json) {
    final formats =
        json['supported_formats'] != null
            ? List<String>.from(json['supported_formats'])
            : <String>[];

    final languagesList = <Map<String, String>>[];
    if (json['book_languages'] != null) {
      for (var item in json['book_languages']) {
        languagesList.add({
          'code': item['code'] as String,
          'language': item['language'] as String,
        });
      }
    }

    final defaultLang =
        json['default_language'] != null
            ? List<String>.from(json['default_language'])
            : <String>['en'];

    return DownloadConfigModel(
      supportedFormats: formats,
      languages: languagesList,
      defaultLanguage: defaultLang,
    );
  }
}
