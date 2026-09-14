import 'package:calibre_web_companion/core/utils/pubdate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePubdate', () {
    test('parses ISO dates from calibre and calibre-web', () {
      expect(parsePubdate('1990-01-15T00:00:00+00:00'), isNotNull);
      expect(parsePubdate('2001-09-11 00:00:00')?.year, 2001);
    });

    test('treats placeholders as no date (#197)', () {
      expect(parsePubdate('None'), isNull);
      expect(parsePubdate(''), isNull);
      expect(parsePubdate(null), isNull);
      expect(parsePubdate('unknown'), isNull);
      expect(parsePubdate('0101-01-01T00:00:00+00:00'), isNull);
    });
  });
}
