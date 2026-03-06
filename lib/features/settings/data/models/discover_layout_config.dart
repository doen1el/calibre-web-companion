enum DiscoverMainSection { discover, categories }

extension DiscoverMainSectionX on DiscoverMainSection {
  String get key {
    switch (this) {
      case DiscoverMainSection.discover:
        return 'discover';
      case DiscoverMainSection.categories:
        return 'categories';
    }
  }

  static DiscoverMainSection? fromKey(String key) {
    for (final section in DiscoverMainSection.values) {
      if (section.key == key) return section;
    }
    return null;
  }
}

enum DiscoverItem { discover, hotBooks, newBooks, ratedBooks }

extension DiscoverItemX on DiscoverItem {
  String get key {
    switch (this) {
      case DiscoverItem.discover:
        return 'discover';
      case DiscoverItem.hotBooks:
        return 'hot_books';
      case DiscoverItem.newBooks:
        return 'new_books';
      case DiscoverItem.ratedBooks:
        return 'rated_books';
    }
  }

  static DiscoverItem? fromKey(String key) {
    for (final item in DiscoverItem.values) {
      if (item.key == key) return item;
    }
    return null;
  }
}

enum CategoryItem {
  authors,
  categories,
  series,
  formats,
  languages,
  publishers,
  ratings,
}

extension CategoryItemX on CategoryItem {
  String get key {
    switch (this) {
      case CategoryItem.authors:
        return 'authors';
      case CategoryItem.categories:
        return 'categories';
      case CategoryItem.series:
        return 'series';
      case CategoryItem.formats:
        return 'formats';
      case CategoryItem.languages:
        return 'languages';
      case CategoryItem.publishers:
        return 'publishers';
      case CategoryItem.ratings:
        return 'ratings';
    }
  }

  static CategoryItem? fromKey(String key) {
    for (final item in CategoryItem.values) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class DiscoverLayoutConfig {
  static final List<String> defaultMainSectionsOrder =
      DiscoverMainSection.values.map((section) => section.key).toList();
  static final List<String> defaultDiscoverItemsOrder =
      DiscoverItem.values.map((item) => item.key).toList();
  static final List<String> defaultCategoryItemsOrder =
      CategoryItem.values.map((item) => item.key).toList();

  static List<String> normalizeMainSectionsOrder(List<String> order) {
    final known =
        order
            .where(
              (sectionKey) => DiscoverMainSectionX.fromKey(sectionKey) != null,
            )
            .toList();
    final missing = defaultMainSectionsOrder.where(
      (sectionKey) => !known.contains(sectionKey),
    );
    return [...known, ...missing];
  }

  static List<String> normalizeEnabledMainSections(List<String> enabled) {
    return enabled
        .where((sectionKey) => DiscoverMainSectionX.fromKey(sectionKey) != null)
        .toList();
  }

  static List<String> normalizeDiscoverItemsOrder(List<String> order) {
    final known =
        order
            .where((itemKey) => DiscoverItemX.fromKey(itemKey) != null)
            .toList();
    final missing = defaultDiscoverItemsOrder.where(
      (itemKey) => !known.contains(itemKey),
    );
    return [...known, ...missing];
  }

  static List<String> normalizeEnabledDiscoverItems(List<String> enabled) {
    return enabled
        .where((itemKey) => DiscoverItemX.fromKey(itemKey) != null)
        .toList();
  }

  static List<String> normalizeCategoryItemsOrder(List<String> order) {
    final known =
        order
            .where((itemKey) => CategoryItemX.fromKey(itemKey) != null)
            .toList();
    final missing = defaultCategoryItemsOrder.where(
      (itemKey) => !known.contains(itemKey),
    );
    return [...known, ...missing];
  }

  static List<String> normalizeEnabledCategoryItems(List<String> enabled) {
    return enabled
        .where((itemKey) => CategoryItemX.fromKey(itemKey) != null)
        .toList();
  }
}
