// Follows Python's unidecode, which Calibre-Web uses for its "convert
// non-English characters" file names and the KOReader sync plugin mirrors.
const Map<String, String> _asciiGroups = {
  'ÀÁÂÃÄÅĀĂĄ': 'A',
  'àáâãäåāăą': 'a',
  'Æ': 'AE',
  'æ': 'ae',
  'ÇĆĈĊČ': 'C',
  'çćĉċč': 'c',
  'ÐĎĐ': 'D',
  'ðďđ': 'd',
  'ÈÉÊËĒĔĖĘĚ': 'E',
  'èéêëēĕėęě': 'e',
  'ĜĞĠĢ': 'G',
  'ĝğġģ': 'g',
  'ĤĦ': 'H',
  'ĥħ': 'h',
  'ÌÍÎÏĨĪĬĮİ': 'I',
  'ìíîïĩīĭįı': 'i',
  'Ĳ': 'IJ',
  'ĳ': 'ij',
  'Ĵ': 'J',
  'ĵ': 'j',
  'Ķ': 'K',
  'ķĸ': 'k',
  'ĹĻĽĿŁ': 'L',
  'ĺļľŀł': 'l',
  'ÑŃŅŇ': 'N',
  'ñńņň': 'n',
  'Ŋ': 'NG',
  'ŋ': 'ng',
  'ÒÓÔÕÖØŌŎŐ': 'O',
  'òóôõöøōŏő': 'o',
  'Œ': 'OE',
  'œ': 'oe',
  'ŔŖŘ': 'R',
  'ŕŗř': 'r',
  'ŚŜŞŠȘ': 'S',
  'śŝşšșſ': 's',
  'ß': 'ss',
  'ŢŤŦȚ': 'T',
  'ţťŧț': 't',
  'Þ': 'Th',
  'þ': 'th',
  'ÙÚÛÜŨŪŬŮŰŲ': 'U',
  'ùúûüũūŭůűų': 'u',
  'Ŵ': 'W',
  'ŵ': 'w',
  'ÝŶŸ': 'Y',
  'ýÿŷ': 'y',
  'ŹŻŽ': 'Z',
  'źżž': 'z',
  '‘’‚‛′': "'",
  '“”„‟″': '"',
  '‐‑‒–': '-',
  '—―': '--',
  '…': '...',
  '×': 'x',
  '«': '<<',
  '»': '>>',
  ' ': ' ',
};

final Map<int, String> _asciiMap = {
  for (final entry in _asciiGroups.entries)
    for (final rune in entry.key.runes) rune: entry.value,
};

/// Replaces accented and special Latin characters with ASCII (ä → a,
/// ß → ss, ð → d); characters without a mapping are kept.
String transliterateToAscii(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    // combining diacritics of decomposed input ("ä")
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final replacement = _asciiMap[rune];
    if (replacement != null) {
      buffer.write(replacement);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// File name from a Content-Disposition header; `filename*` wins over
/// `filename`. Calibre-Web percent-encodes both.
String? fileNameFromContentDisposition(String? header) {
  if (header == null || header.trim().isEmpty) return null;

  String? extended;
  String? plain;
  for (final part in _splitParams(header)) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    final key = part.substring(0, eq).trim().toLowerCase();
    var value = part.substring(eq + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1).replaceAll(r'\"', '"');
    }
    if (key == 'filename*') {
      final quote = value.indexOf("''");
      final encoded = quote >= 0 ? value.substring(quote + 2) : value;
      extended = _percentDecode(encoded);
    } else if (key == 'filename') {
      plain = _percentDecode(value);
    }
  }

  final name = (extended?.trim().isNotEmpty ?? false) ? extended : plain;
  if (name == null) return null;
  // never trust a path from the server
  final baseName = name.split(RegExp(r'[/\\]')).last.trim();
  return baseName.isEmpty ? null : baseName;
}

/// Strips [format]'s extension (or `.kepub.epub`) from a server file name.
String stripBookExtension(String fileName, String format) {
  final lower = fileName.toLowerCase();
  for (final suffix in ['.kepub.epub', '.${format.toLowerCase()}']) {
    if (lower.endsWith(suffix) && fileName.length > suffix.length) {
      return fileName.substring(0, fileName.length - suffix.length);
    }
  }
  return fileName;
}

Iterable<String> _splitParams(String header) sync* {
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < header.length; i++) {
    final char = header[i];
    if (char == '"' && (i == 0 || header[i - 1] != r'\')) {
      inQuotes = !inQuotes;
    }
    if (char == ';' && !inQuotes) {
      yield buffer.toString();
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  if (buffer.isNotEmpty) yield buffer.toString();
}

String _percentDecode(String value) {
  if (!value.contains('%')) return value;
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  } on FormatException {
    return value;
  }
}
