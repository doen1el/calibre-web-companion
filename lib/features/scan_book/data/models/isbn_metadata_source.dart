enum IsbnMetadataSource {
  openLibrary('open_library', 'Open Library'),
  googleBooks('google_books', 'Google Books'),
  bnf('bnf', 'BnF'),
  hardcover('hardcover', 'Hardcover'),
  isbnDb('isbndb', 'ISBNdb');

  const IsbnMetadataSource(this.id, this.label);

  final String id;
  final String label;

  bool get requiresCredential =>
      this == IsbnMetadataSource.hardcover || this == IsbnMetadataSource.isbnDb;

  bool get acceptsCredential =>
      requiresCredential || this == IsbnMetadataSource.googleBooks;

  String get credentialKey => switch (this) {
    IsbnMetadataSource.googleBooks => 'isbn_source_google_books_key',
    IsbnMetadataSource.hardcover => 'isbn_source_hardcover_token',
    IsbnMetadataSource.isbnDb => 'isbn_source_isbndb_key',
    _ => '',
  };

  String get infoUrl => switch (this) {
    IsbnMetadataSource.openLibrary => 'https://openlibrary.org',
    IsbnMetadataSource.googleBooks =>
      'https://developers.google.com/books/docs/v1/using#APIKey',
    IsbnMetadataSource.bnf => 'https://catalogue.bnf.fr',
    IsbnMetadataSource.hardcover => 'https://hardcover.app/account/api',
    IsbnMetadataSource.isbnDb => 'https://isbndb.com/isbn-database',
  };

  static const List<IsbnMetadataSource> defaultEnabled = [
    IsbnMetadataSource.openLibrary,
    IsbnMetadataSource.googleBooks,
    IsbnMetadataSource.bnf,
  ];

  static IsbnMetadataSource? fromId(String id) {
    for (final source in IsbnMetadataSource.values) {
      if (source.id == id) return source;
    }
    return null;
  }
}
