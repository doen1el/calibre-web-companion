enum DownloadSchema {
  flat, // Just the book file in the selected directory
  authorOnly, // author/book.epub
  authorBook, // author/book/book.epub
  authorSeriesBook, // author/series/book/book.epub
}
