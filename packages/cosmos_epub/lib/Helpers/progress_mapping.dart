/// Maps a whole-book percentage onto a chapter of the flattened chapter list.
int chapterIndexForPercentage(List<int> weights, double percentage) {
  if (weights.isEmpty) return 0;

  final clamped = percentage.isNaN ? 0.0 : percentage.clamp(0.0, 100.0);

  var total = 0;
  for (final weight in weights) {
    total += weight > 0 ? weight : 0;
  }

  // Without usable weights the only honest fallback is an even split.
  if (total <= 0) {
    final index = (clamped / 100 * weights.length).floor();
    return index.clamp(0, weights.length - 1);
  }

  final target = total * clamped / 100;

  var consumed = 0;
  for (var i = 0; i < weights.length; i++) {
    consumed += weights[i] > 0 ? weights[i] : 0;
    if (target < consumed) return i;
  }

  return weights.length - 1;
}

/// How far into chapter [chapterIndex] a whole-book [percentage] falls, as 0-1.
///
/// [chapterIndexForPercentage] answers which chapter; this answers where in it,
/// which is what turns a synced position into a page once the chapter has been
/// laid out for this screen.
double fractionWithinChapter(
  List<int> weights,
  int chapterIndex,
  double percentage,
) {
  if (weights.isEmpty) return 0;
  if (chapterIndex < 0 || chapterIndex >= weights.length) return 0;

  final clamped = percentage.isNaN ? 0.0 : percentage.clamp(0.0, 100.0);

  var total = 0;
  for (final weight in weights) {
    total += weight > 0 ? weight : 0;
  }
  if (total <= 0) return 0;

  var before = 0;
  for (var i = 0; i < chapterIndex; i++) {
    before += weights[i] > 0 ? weights[i] : 0;
  }

  final own = weights[chapterIndex] > 0 ? weights[chapterIndex] : 0;
  if (own <= 0) return 0;

  final target = total * clamped / 100;
  return ((target - before) / own).clamp(0.0, 1.0);
}

/// The page [fraction] (0-1) of the way through a chapter of [pageCount] pages.
int pageIndexForFraction(double fraction, int pageCount) {
  if (pageCount <= 1) return 0;
  final clamped = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
  return (clamped * (pageCount - 1)).round().clamp(0, pageCount - 1);
}

/// The inverse: a position inside a chapter as a percentage of the whole book.
///
/// [pageIndex] / [pageCount] locate the reader inside chapter [chapterIndex];
/// paging is device-specific, so this fraction only refines the chapter the
/// position sits in. Returns 0-100.
double percentageForPosition(
  List<int> weights,
  int chapterIndex,
  int pageIndex,
  int pageCount,
) {
  if (weights.isEmpty) return 0;

  final chapter = chapterIndex.clamp(0, weights.length - 1);

  var total = 0;
  for (final weight in weights) {
    total += weight > 0 ? weight : 0;
  }
  if (total <= 0) {
    return ((chapter + 1) / weights.length * 100).clamp(0.0, 100.0);
  }

  var before = 0;
  for (var i = 0; i < chapter; i++) {
    before += weights[i] > 0 ? weights[i] : 0;
  }

  final own = weights[chapter] > 0 ? weights[chapter] : 0;
  final withinChapter =
      pageCount > 1 ? (pageIndex.clamp(0, pageCount - 1)) / (pageCount - 1) : 0;

  return ((before + own * withinChapter) / total * 100).clamp(0.0, 100.0);
}
