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

  /// Keeps single path segments below the Android file name limit.
  static const int maxSegmentLength = 120;

  static final RegExp _illegalChars = RegExp(r'[\\/:*?"<>|\x00-\x1f]');
  static final RegExp _placeholder = RegExp(r'\{([^{}]*)\}');
  static final RegExp _multipleSpaces = RegExp(r'\s+');
  static final RegExp _customFieldNoise = RegExp(r'[^a-z0-9_]');

  /// Subset of the python format spec calibre supports:
  /// `[[fill]align][sign][#][0][width][,][.precision][type]`
  static final RegExp _formatSpec = RegExp(
    r'^(?:(.)?([<>^=]))?([+\- ])?(#)?(0)?(\d+)?(,)?(?:\.(\d+))?([bcdeEfFgGnosxX%])?$',
  );

  /// Calibre field names that mean the same as one of our tokens.
  static const Map<String, String> _fieldAliases = {
    'authors': 'author',
    'author_sort': 'author_sort',
    'publishers': 'publisher',
    'languages': 'language',
    'lang': 'language',
    'book_id': 'id',
  };

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
      final segment = _cleanSegment(_expand(rawSegment, values));
      if (segment.isNotEmpty) segments.add(segment);
    }

    if (segments.isEmpty) {
      final fallback = _cleanSegment(sanitize(fallbackName));
      return [fallback.isEmpty ? 'book' : fallback];
    }
    return segments;
  }

  /// Custom column fields (`{#library}`) used by [template], normalized the
  /// same way as the keys expected in the values map.
  static Set<String> customColumnFields(String template) {
    final fields = <String>{};
    for (final match in _placeholder.allMatches(template)) {
      final field = _fieldOf(match[1]!);
      if (field.startsWith('#')) fields.add(normalizeCustomField(field));
    }
    return fields;
  }

  /// Custom columns are looked up by their label, which calibre-web only
  /// exposes as a display name ("My Library" -> `#my_library`).
  static String normalizeCustomField(String field) {
    final label = field
        .replaceFirst('#', '')
        .trim()
        .toLowerCase()
        .replaceAll(_multipleSpaces, '_')
        .replaceAll('-', '_')
        .replaceAll(_customFieldNoise, '');
    return '#$label';
  }

  /// Removes characters that are illegal in file names on Android/SAF.
  static String sanitize(String value) => _stripIllegal(value).trim();

  /// The file name additionally must not contain a dot: the SAF plugin derives
  /// the mime type from the first dot in the name, so `Vol. 1.epub` would be
  /// created as a "1" file and fail.
  static String sanitizeFileName(String value) {
    final withoutDots = value.replaceAll('.', ' ');
    return _cleanSegment(sanitize(withoutDots));
  }

  static String _stripIllegal(String value) =>
      value.replaceAll(_illegalChars, '');

  static String _expand(String segment, Map<String, String> values) {
    return segment.replaceAllMapped(_placeholder, (match) {
      final body = match[1]!;
      final field = _fieldOf(body);
      final spec = _specOf(body);

      var format = spec;
      var prefix = '';
      var suffix = '';
      if (spec.contains('|')) {
        final parts = spec.split('|');
        format = parts[0];
        prefix = parts.length > 1 ? parts[1] : '';
        suffix = parts.length > 2 ? parts.sublist(2).join('|') : '';
      }

      // An empty field stays empty: formatting it first would turn `{x:0>2s}`
      // into "00" and make the field look filled, prefix and suffix included.
      var value = sanitize(_lookup(field, values));
      if (value.isEmpty) return '';

      if (format.isNotEmpty) value = _applyFormat(value, format).trim();
      if (value.isEmpty) return '';

      return '${_stripIllegal(prefix)}$value${_stripIllegal(suffix)}';
    });
  }

  static String _fieldOf(String body) {
    final colon = body.indexOf(':');
    return (colon == -1 ? body : body.substring(0, colon)).trim();
  }

  static String _specOf(String body) {
    final colon = body.indexOf(':');
    return colon == -1 ? '' : body.substring(colon + 1);
  }

  static String _lookup(String field, Map<String, String> values) {
    if (field.isEmpty) return '';
    if (field.startsWith('#')) {
      return values[normalizeCustomField(field)] ?? '';
    }
    final key = field.toLowerCase();
    return values[key] ?? values[_fieldAliases[key] ?? key] ?? '';
  }

  /// Applies a python style format spec. Anything we don't understand (calibre
  /// template functions like `re(...)`) leaves the value untouched.
  static String _applyFormat(String value, String spec) {
    final match = _formatSpec.firstMatch(spec);
    if (match == null) return value;

    final align = match[2];
    final zeroPad = match[5] != null;
    final width = int.tryParse(match[6] ?? '');
    final precision = int.tryParse(match[8] ?? '');
    final type = match[9];

    var result = value;
    var numeric = false;

    switch (type) {
      case 'd':
      case 'n':
        final number = num.tryParse(value);
        if (number == null) return value;
        result = number.round().toString();
        numeric = true;
      case 'f':
      case 'F':
        final number = num.tryParse(value);
        if (number == null) return value;
        result = number.toDouble().toStringAsFixed(precision ?? 6);
        numeric = true;
      default:
        if (precision != null && precision < result.length) {
          result = result.substring(0, precision);
        }
    }

    if (width == null || width <= result.length) return result;

    final fill = match[1] ?? (zeroPad ? '0' : ' ');
    final padding = fill * (width - result.length);
    final effectiveAlign =
        align ?? (numeric || zeroPad || fill == '0' ? '>' : '<');

    switch (effectiveAlign) {
      case '<':
        return '$result$padding';
      case '^':
        final left = padding.substring(0, padding.length ~/ 2);
        final right = padding.substring(padding.length ~/ 2);
        return '$left$result$right';
      default:
        return '$padding$result';
    }
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
    result = result.substring(start, end);

    if (result.length > maxSegmentLength) {
      result = result.substring(0, maxSegmentLength).trimRight();
    }
    return result;
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
    final values = previewValues;
    // Custom columns have no sample value, so the preview shows the label.
    for (final field in customColumnFields(template)) {
      values[field] = field.substring(1);
    }

    final segments = resolve(
      template,
      values,
      fallbackName: previewValues[DownloadPathToken.title.key]!,
    );
    final fileName = sanitizeFileName(segments.last);
    final folders = segments.take(segments.length - 1);

    return '/${[...folders, '$fileName.$format'].join('/')}';
  }
}
