/// Building blocks for the user defined download path.
enum DownloadPathToken {
  title('title'),
  author('author'),
  authorSort('author_sort'),
  series('series'),
  seriesIndex('series_index'),
  publisher('publisher'),
  year('year'),
  language('language'),
  format('format'),
  id('id');

  const DownloadPathToken(this.key);

  final String key;

  String get placeholder => '{$key}';
}

/// Resolves a path template like `{author}/{series}/{title}` into path
/// segments. The last segment is the file name (without extension).
class DownloadPathTemplate {
  static const String defaultTemplate = '{author}/{series}/{title}';

  static final RegExp _illegalChars = RegExp(r'[\\/:*?"<>|\x00-\x1f]');
  static final RegExp _anyPlaceholder = RegExp(r'\{[a-z_]*\}');
  static final RegExp _multipleSpaces = RegExp(r'\s+');

  /// Characters that make no sense at the start or end of a segment once a
  /// token resolved to an empty value (e.g. `{series_index} - {title}`
  /// without a series index).
  static const String _trimmableChars = ' -–—_,.·|';

  static List<String> resolve(
    String template,
    Map<String, String> values, {
    required String fallbackName,
  }) {
    final segments = <String>[];

    for (final rawSegment in template.split('/')) {
      var segment = rawSegment;
      for (final entry in values.entries) {
        segment = segment.replaceAll('{${entry.key}}', sanitize(entry.value));
      }
      // Anything left is an unknown token and resolves to nothing
      segment = segment.replaceAll(_anyPlaceholder, '');

      segment = _cleanSegment(segment);
      if (segment.isNotEmpty) segments.add(segment);
    }

    if (segments.isEmpty) {
      final fallback = _cleanSegment(sanitize(fallbackName));
      return [fallback.isEmpty ? 'book' : fallback];
    }
    return segments;
  }

  /// Removes characters that are illegal in file names on Android/SAF.
  static String sanitize(String value) {
    return value.replaceAll(_illegalChars, '').trim();
  }

  static String _cleanSegment(String segment) {
    var result = segment.replaceAll(_multipleSpaces, ' ');

    int start = 0;
    int end = result.length;
    while (start < end && _trimmableChars.contains(result[start])) {
      start++;
    }
    while (end > start && _trimmableChars.contains(result[end - 1])) {
      end--;
    }
    return result.substring(start, end);
  }

  /// Series indices are padded so that `10 - Book` sorts after `02 - Book`.
  static String formatSeriesIndex(double index) {
    if (index <= 0) return '';
    if (index == index.truncateToDouble()) {
      return index.toInt().toString().padLeft(2, '0');
    }
    return index.toString();
  }

  static String yearFromPubdate(String pubdate) {
    if (pubdate.length < 4) return '';
    final year = pubdate.substring(0, 4);
    return int.tryParse(year) != null ? year : '';
  }

  /// Example values used for the live preview in the settings.
  static Map<String, String> get previewValues => {
    DownloadPathToken.title.key: 'The Eye of the World',
    DownloadPathToken.author.key: 'Robert Jordan',
    DownloadPathToken.authorSort.key: 'Jordan, Robert',
    DownloadPathToken.series.key: 'The Wheel of Time',
    DownloadPathToken.seriesIndex.key: '01',
    DownloadPathToken.publisher.key: 'Tor Books',
    DownloadPathToken.year.key: '1990',
    DownloadPathToken.language.key: 'eng',
    DownloadPathToken.format.key: 'epub',
    DownloadPathToken.id.key: '42',
  };

  static String preview(String template, {String format = 'epub'}) {
    final segments = resolve(
      template,
      previewValues,
      fallbackName: previewValues[DownloadPathToken.title.key]!,
    );
    return '/${segments.join('/')}.$format';
  }
}
