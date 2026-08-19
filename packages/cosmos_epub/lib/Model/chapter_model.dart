class LocalChapterModel {
  final String chapter;
  final int depth;
  final String htmlContent;
  final bool isSectionTitle;
  final String sourceHref;

  LocalChapterModel({
    required this.chapter,
    this.depth = 0,
    this.htmlContent = '',
    this.isSectionTitle = false,
    this.sourceHref = '',
  });
}
