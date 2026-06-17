class BookProgressModel {
  String? bookId;
  int? currentChapterIndex;
  int? currentPageIndex;

  BookProgressModel({
    this.currentChapterIndex,
    this.currentPageIndex,
    this.bookId,
  });
}
