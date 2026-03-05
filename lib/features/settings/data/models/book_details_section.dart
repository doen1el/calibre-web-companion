enum BookDetailsSection {
  bookActions,
  rating,
  series,
  publicationInfo,
  fileInfo,
  tags,
  description,
}

extension BookDetailsSectionX on BookDetailsSection {
  String get key {
    switch (this) {
      case BookDetailsSection.bookActions:
        return 'book_actions';
      case BookDetailsSection.rating:
        return 'rating';
      case BookDetailsSection.series:
        return 'series';
      case BookDetailsSection.publicationInfo:
        return 'publication_info';
      case BookDetailsSection.fileInfo:
        return 'file_info';
      case BookDetailsSection.tags:
        return 'tags';
      case BookDetailsSection.description:
        return 'description';
    }
  }

  static BookDetailsSection? fromKey(String key) {
    for (final section in BookDetailsSection.values) {
      if (section.key == key) return section;
    }
    return null;
  }
}

class BookDetailsSectionConfig {
  static final List<String> defaultOrder =
      BookDetailsSection.values.map((section) => section.key).toList();

  static List<String> normalizeOrder(List<String> order) {
    final known =
        order
            .where(
              (sectionKey) => BookDetailsSectionX.fromKey(sectionKey) != null,
            )
            .toList();
    final missing = defaultOrder.where(
      (sectionKey) => !known.contains(sectionKey),
    );
    return [...known, ...missing];
  }

  static List<String> normalizeEnabled(List<String> enabled) {
    return enabled
        .where((sectionKey) => BookDetailsSectionX.fromKey(sectionKey) != null)
        .toList();
  }
}
