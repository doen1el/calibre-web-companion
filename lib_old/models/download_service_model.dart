enum DownloaderStatus {
  available,
  downloading,
  done,
  error,
  queued,
  notDownloaded,
}

class Book {
  final String id;
  final String title;
  final String author;
  final String format;
  final String size;
  final String preview;
  final String publisher;
  final int year;
  final String language;
  final DownloaderStatus status;
  final List<String> downloadUrls;
  final String? errorMessage;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.size,
    required this.preview,
    required this.publisher,
    required this.year,
    required this.language,
    this.status = DownloaderStatus.notDownloaded,
    this.downloadUrls = const [],
    this.errorMessage,
  });

  // Create a book from search results
  factory Book.fromSearchResponse(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      format: json['format'] ?? 'Unknown Format',
      size: json['size'] ?? 'Unknown Size',
      preview: json['preview'] ?? '',
      publisher: json['publisher'] ?? 'Unknown Publisher',
      year:
          json['year'] is String
              ? int.tryParse(json['year']) ?? 0
              : json['year'] ?? 0,
      language: json['language'] ?? 'Unknown',
      downloadUrls: List<String>.from(json['download_urls'] ?? []),
    );
  }

  // Convert book to a map for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'format': format,
      'size': size,
      'preview': preview,
      'publisher': publisher,
      'year': year,
      'language': language,
      'download_urls': downloadUrls,
    };
  }

  // Create a copy of this book with a different status
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? format,
    String? size,
    String? preview,
    String? publisher,
    int? year,
    String? language,
    DownloaderStatus? status,
    List<String>? downloadUrls,
    String? errorMessage,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format ?? this.format,
      size: size ?? this.size,
      preview: preview ?? this.preview,
      publisher: publisher ?? this.publisher,
      year: year ?? this.year,
      language: language ?? this.language,
      status: status ?? this.status,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DownloadStatusResponse {
  final Map<String, dynamic> available;
  final Map<String, dynamic> done;
  final Map<String, dynamic> downloading;
  final Map<String, dynamic> error;
  final Map<String, dynamic> queued;

  DownloadStatusResponse({
    required this.available,
    required this.done,
    required this.downloading,
    required this.error,
    required this.queued,
  });

  factory DownloadStatusResponse.fromJson(Map<String, dynamic> json) {
    return DownloadStatusResponse(
      available: json['available'] ?? {},
      done: json['done'] ?? {},
      downloading: json['downloading'] ?? {},
      error: json['error'] ?? {},
      queued: json['queued'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'done': done,
      'downloading': downloading,
      'error': error,
      'queued': queued,
    };
  }

  /// Converts the nested JSON structure into a flat list of book objects with their status
  List<Book> getAllBooks() {
    final List<Book> allBooks = [];

    // Process books in 'available' status
    available.forEach((id, bookData) {
      allBooks.add(
        _createBookFromData(id, bookData, DownloaderStatus.available),
      );
    });

    // Process books in 'done' status
    done.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.done));
    });

    // Process books in 'downloading' status
    downloading.forEach((id, bookData) {
      allBooks.add(
        _createBookFromData(id, bookData, DownloaderStatus.downloading),
      );
    });

    // Process books in 'error' status
    error.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.error));
    });

    // Process books in 'queued' status
    queued.forEach((id, bookData) {
      allBooks.add(_createBookFromData(id, bookData, DownloaderStatus.queued));
    });

    return allBooks;
  }

  Book _createBookFromData(String id, dynamic data, DownloaderStatus status) {
    // Handle both string and map types for data
    if (data is! Map<String, dynamic>) {
      return Book(
        id: id,
        title: 'Unknown',
        author: 'Unknown',
        format: 'Unknown',
        size: 'Unknown',
        preview: '',
        publisher: 'Unknown',
        year: 0,
        language: 'Unknown',
        status: status,
      );
    }

    return Book(
      id: id,
      title: data['title'] ?? 'Unknown Title',
      author: data['author'] ?? 'Unknown Author',
      format: data['format'] ?? 'Unknown Format',
      size: data['size'] ?? 'Unknown Size',
      preview: data['preview'] ?? '',
      publisher: data['publisher'] ?? 'Unknown Publisher',
      year:
          data['year'] is String
              ? int.tryParse(data['year']) ?? 0
              : data['year'] ?? 0,
      language: data['language'] ?? 'Unknown',
      status: status,
      downloadUrls:
          data['download_urls'] != null
              ? List<String>.from(data['download_urls'])
              : [],
      errorMessage:
          status == DownloaderStatus.error
              ? data['error_message']?.toString()
              : null,
    );
  }
}
