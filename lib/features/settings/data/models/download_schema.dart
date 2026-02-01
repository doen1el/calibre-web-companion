enum DownloadSchema {
  flat, // Just the book file in the selected directory
  authorOnly, // author/book.epub
  authorBook, // author/book/book.epub
  authorSeriesBook, // author/series/book/book.epub
  authorSortOnly, // author_sort/book.epub
  authorSortBook, // author_sort/book/book.epub
  authorSortSeriesBook, // author_sort/series/book/book.epub
}
