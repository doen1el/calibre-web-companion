import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/models/custom_column_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Markup of stock calibre-web's `detail.html`.
const _stockMarkup = '''
<div class="real_custom_columns">
    Library:
    Manuals
</div>
<div class="real_custom_columns">
    Read Again:
    <span class="glyphicon glyphicon-ok"></span>
</div>
<div class="real_custom_columns">
    Owned:
    <span class="glyphicon glyphicon-remove"></span>
</div>
<div class="real_custom_columns">
    Moods:
    cozy, dark
</div>
''';

/// Markup of Calibre-Web-NextGen, which wraps name and value in spans.
const _nextGenMarkup = '''
<div class="real_custom_columns meta-chip">
    <span class="meta-label">My Library:</span>
    <span class="meta-value">
        Manuals
    </span>
</div>
''';

void main() {
  List<CustomColumnModel> parse(String html) =>
      BookDetailsRemoteDatasource.parseCustomColumnsFromDetailPage(html);

  Map<String, String> templateValues(String html) =>
      BookDetailsRemoteDatasource.customColumnTemplateValues(parse(html));

  group('custom columns on the calibre-web detail page', () {
    test('reads columns from stock calibre-web markup', () {
      expect(templateValues(_stockMarkup)['#library'], 'Manuals');
      expect(parse(_stockMarkup).first.name, 'Library');
    });

    test('reads columns from NextGen markup', () {
      expect(templateValues(_nextGenMarkup)['#my_library'], 'Manuals');
      expect(parse(_nextGenMarkup).single.name, 'My Library');
    });

    test('keeps multi-value text columns joined', () {
      expect(templateValues(_stockMarkup)['#moods'], 'cozy, dark');
    });

    test('reads yes/no columns from their icon', () {
      final columns = {for (final c in parse(_stockMarkup)) c.key: c};
      expect(columns['#read_again']?.boolValue, isTrue);
      expect(columns['#owned']?.boolValue, isFalse);
    });

    test('leaves yes/no columns out of path template values', () {
      expect(templateValues(_stockMarkup).containsKey('#read_again'), isFalse);
    });

    test('returns nothing for a page without custom columns', () {
      expect(parse('<html><body><h1>No columns</h1></body></html>'), isEmpty);
    });
  });

  group('custom columns from calibre user_metadata', () {
    final columns = {
      for (final c in BookDetailsRemoteDatasource.parseCalibreUserMetadata({
        '#library': {
          'name': 'My Library',
          'datatype': 'text',
          '#value#': 'Manuals',
        },
        '#moods': {
          'name': 'Moods',
          'datatype': 'text',
          '#value#': ['cozy', 'dark'],
        },
        '#stars': {'name': 'Stars', 'datatype': 'rating', '#value#': 7},
        '#finished': {
          'name': 'Finished',
          'datatype': 'datetime',
          '#value#': '2024-03-05T12:00:00+00:00',
        },
        '#never': {
          'name': 'Never',
          'datatype': 'datetime',
          '#value#': '0101-01-01T00:00:00+00:00',
        },
        '#notes': {
          'name': 'Notes',
          'datatype': 'comments',
          '#value#': '<p>Great <b>read</b></p>',
        },
        '#saga': {
          'name': 'Saga',
          'datatype': 'series',
          '#value#': 'Dune',
          '#extra#': 2.0,
        },
        '#owned': {'name': 'Owned', 'datatype': 'bool', '#value#': true},
        '#empty': {'name': 'Empty', 'datatype': 'text', '#value#': null},
      }))
        c.key: c,
    };

    test('uses the display name and label', () {
      expect(columns['#library']?.name, 'My Library');
      expect(columns['#library']?.value, 'Manuals');
    });

    test('formats values the way calibre-web shows them', () {
      expect(columns['#moods']?.value, 'cozy, dark');
      expect(columns['#stars']?.value, '3.5');
      expect(columns['#finished']?.value, '2024-03-05');
      expect(columns['#notes']?.value, 'Great read');
      expect(columns['#saga']?.value, 'Dune [2]');
      expect(columns['#owned']?.boolValue, isTrue);
    });

    test('skips unset values', () {
      expect(columns.containsKey('#empty'), isFalse);
      expect(columns.containsKey('#never'), isFalse);
    });
  });
}
