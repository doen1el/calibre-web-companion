// Returns null for placeholder dates: calibre sends `None` for a missing
// pubdate and year 101 for its UNDEFINED_DATE.
DateTime? parsePubdate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.year <= 101) return null;
  return parsed;
}
