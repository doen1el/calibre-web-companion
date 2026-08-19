import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
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
  Map<String, String> parse(String html) =>
      BookDetailsRemoteDatasource.parseCustomColumnsFromDetailPage(html);

  group('custom columns on the calibre-web detail page', () {
    test('reads columns from stock calibre-web markup', () {
      expect(parse(_stockMarkup)['#library'], 'Manuals');
    });

    test('reads columns from NextGen markup', () {
      expect(parse(_nextGenMarkup)['#my_library'], 'Manuals');
    });

    test('skips columns that render without a text value', () {
      expect(parse(_stockMarkup).containsKey('#read_again'), isFalse);
    });

    test('returns nothing for a page without custom columns', () {
      expect(parse('<html><body><h1>No columns</h1></body></html>'), isEmpty);
    });
  });
}
