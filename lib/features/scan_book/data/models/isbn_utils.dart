String normalizeIsbn(String raw) =>
    raw.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

bool isValidIsbnLength(String normalized) =>
    normalized.length == 10 || normalized.length == 13;

String? toIsbn13(String normalized) {
  if (normalized.length == 13) return normalized;
  if (normalized.length != 10) return null;

  final body = '978${normalized.substring(0, 9)}';
  var sum = 0;
  for (var i = 0; i < body.length; i++) {
    final digit = int.tryParse(body[i]);
    if (digit == null) return null;
    sum += digit * (i.isEven ? 1 : 3);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$body$check';
}

String? toIsbn10(String normalized) {
  if (normalized.length == 10) return normalized;
  if (normalized.length != 13 || !normalized.startsWith('978')) return null;

  final body = normalized.substring(3, 12);
  var sum = 0;
  for (var i = 0; i < body.length; i++) {
    final digit = int.tryParse(body[i]);
    if (digit == null) return null;
    sum += digit * (10 - i);
  }
  final check = (11 - (sum % 11)) % 11;
  return '$body${check == 10 ? 'X' : check}';
}

String normalizeLanguageCode(String raw) {
  final value = raw.trim().toLowerCase().replaceAll('_', '-');
  if (value.isEmpty) return '';
  final base = value.split('-').first;
  if (base.length == 2) return base;

  const map = {
    'eng': 'en',
    'fre': 'fr',
    'fra': 'fr',
    'ger': 'de',
    'deu': 'de',
    'spa': 'es',
    'ita': 'it',
    'dut': 'nl',
    'nld': 'nl',
    'por': 'pt',
    'rus': 'ru',
    'jpn': 'ja',
    'chi': 'zh',
    'zho': 'zh',
    'swe': 'sv',
    'nor': 'no',
    'dan': 'da',
    'fin': 'fi',
    'pol': 'pl',
    'cze': 'cs',
    'ces': 'cs',
    'hun': 'hu',
    'tur': 'tr',
    'ukr': 'uk',
    'cat': 'ca',
    'ara': 'ar',
    'est': 'et',
    'tam': 'ta',
    'gre': 'el',
    'ell': 'el',
    'heb': 'he',
    'kor': 'ko',
    'ron': 'ro',
    'rum': 'ro',
  };
  return map[base] ?? '';
}

final RegExp _catalogRole = RegExp(
  r'\.\s*(auteur|autrice|traducteur|traductrice|illustrateur|illustratrice|'
  r'éditeur|editeur|préfacier|prefacier|adaptateur|compositeur|directeur|'
  r'photographe|narrateur|interprète|interprete|collaborateur)\b.*$',
  caseSensitive: false,
);

String cleanCatalogAuthor(String raw) {
  var name = raw.trim();
  if (name.isEmpty) return '';

  final dates = RegExp(r'\([^)]*\d[^)]*\)').firstMatch(name);
  name =
      dates != null
          ? name.substring(0, dates.start)
          : name.replaceFirst(_catalogRole, '');
  name = name.replaceAll(RegExp(r'[,;]+\s*$'), '').trim();

  if (name.endsWith('.') && !RegExp(r'(^|\s)[A-Z]\.$').hasMatch(name)) {
    name = name.substring(0, name.length - 1).trim();
  }

  final parts = name.split(',');
  if (parts.length == 2) {
    final last = parts[0].trim();
    final first = parts[1].trim();
    if (last.isNotEmpty && first.isNotEmpty) {
      name = '$first $last';
    }
  }
  return name.replaceAll(RegExp(r'\s+'), ' ').trim();
}
