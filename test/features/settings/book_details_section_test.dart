import 'package:calibre_web_companion/features/settings/data/models/book_details_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookDetailsSectionConfig.addNewSections', () {
    test('enables sections added after the user customised the list', () {
      final enabled = ['book_actions', 'description'];

      final migrated = BookDetailsSectionConfig.addNewSections(
        enabled,
        BookDetailsSectionConfig.legacySections,
      );

      expect(migrated, ['book_actions', 'description', 'custom_columns']);
    });

    test('keeps a known section disabled', () {
      final enabled = ['book_actions', 'description'];

      final migrated = BookDetailsSectionConfig.addNewSections(
        enabled,
        BookDetailsSectionConfig.defaultOrder,
      );

      expect(migrated, enabled);
    });
  });
}
