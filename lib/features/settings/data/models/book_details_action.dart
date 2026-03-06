enum BookDetailsAction {
  toggleReadStatus,
  toggleArchiveStatus,
  editMetadata,
  addToShelf,
  downloadToDevice,
  openInInternalReader,
  openInReader,
  openInBrowser,
  deleteBook,
}

extension BookDetailsActionX on BookDetailsAction {
  String get key {
    switch (this) {
      case BookDetailsAction.toggleReadStatus:
        return 'toggle_read_status';
      case BookDetailsAction.toggleArchiveStatus:
        return 'toggle_archive_status';
      case BookDetailsAction.editMetadata:
        return 'edit_metadata';
      case BookDetailsAction.addToShelf:
        return 'add_to_shelf';
      case BookDetailsAction.downloadToDevice:
        return 'download_to_device';
      case BookDetailsAction.openInInternalReader:
        return 'open_in_internal_reader';
      case BookDetailsAction.openInReader:
        return 'open_in_reader';
      case BookDetailsAction.openInBrowser:
        return 'open_in_browser';
      case BookDetailsAction.deleteBook:
        return 'delete_book';
    }
  }

  static BookDetailsAction? fromKey(String key) {
    for (final action in BookDetailsAction.values) {
      if (action.key == key) return action;
    }
    return null;
  }
}

class BookDetailsActionConfig {
  static final List<String> defaultOrder =
      BookDetailsAction.values.map((action) => action.key).toList();

  static List<String> normalizeOrder(List<String> order) {
    final known =
        order
            .where((actionKey) => BookDetailsActionX.fromKey(actionKey) != null)
            .toList();
    final missing = defaultOrder.where(
      (actionKey) => !known.contains(actionKey),
    );
    return [...known, ...missing];
  }

  static List<String> normalizeEnabled(List<String> enabled) {
    final known =
        enabled
            .where((actionKey) => BookDetailsActionX.fromKey(actionKey) != null)
            .toList();
    return known;
  }
}
