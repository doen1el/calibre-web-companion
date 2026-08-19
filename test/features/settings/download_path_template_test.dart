import 'package:calibre_web_companion/features/settings/data/models/download_path_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const values = {
    'title': 'The Eye of the World',
    'author': 'Robert Jordan',
    'author_sort': 'Jordan, Robert',
    'series': 'The Wheel of Time',
    'series_index': '01',
    'publisher': 'Tor Books',
    'year': '1990',
    'language': 'eng',
    'format': 'epub',
    'id': '42',
  };

  List<String> resolve(String template, [Map<String, String>? v]) =>
      DownloadPathTemplate.resolve(
        template,
        v ?? values,
        fallbackName: 'The Eye of the World',
      );

  group('DownloadPathTemplate.resolve', () {
    test('resolves the default template', () {
      expect(resolve(DownloadPathTemplate.defaultTemplate), [
        'Robert Jordan',
        'The Wheel of Time',
        'The Eye of the World',
      ]);
    });

    test('drops segments whose tokens are empty', () {
      final withoutSeries =
          Map<String, String>.from(values)
            ..['series'] = ''
            ..['series_index'] = '';

      expect(resolve('{author}/{series}/{title}', withoutSeries), [
        'Robert Jordan',
        'The Eye of the World',
      ]);
    });

    test('cleans up separators left behind by empty tokens', () {
      final withoutSeries =
          Map<String, String>.from(values)
            ..['series'] = ''
            ..['series_index'] = '';

      expect(resolve('{series}/{series_index} - {title}', withoutSeries), [
        'The Eye of the World',
      ]);
    });

    test('keeps literal text and combines tokens', () {
      expect(resolve('Books/{series} ({year})/{series_index} - {title}'), [
        'Books',
        'The Wheel of Time (1990)',
        '01 - The Eye of the World',
      ]);
    });

    test('strips characters that are illegal in file names', () {
      expect(resolve('{title}', {'title': 'A/B: "C" <D>|E?'}), ['AB C DE']);
    });

    test('ignores unknown tokens and leading slashes', () {
      expect(resolve('/{unknown}/{author}/{title}'), [
        'Robert Jordan',
        'The Eye of the World',
      ]);
    });

    test('falls back to the book title for an empty template', () {
      expect(resolve(''), ['The Eye of the World']);
      expect(resolve('{series}', {'series': ''}), ['The Eye of the World']);
    });

    test('accepts calibre field names', () {
      expect(resolve('{authors}/{languages}/{title}'), [
        'Robert Jordan',
        'eng',
        'The Eye of the World',
      ]);
    });
  });

  group('calibre format specs', () {
    test('truncates with a precision', () {
      expect(resolve('{title:.15}'), ['The Eye of the']);
      expect(resolve('{author_sort:.20}'), ['Jordan, Robert']);
    });

    test('pads with fill and alignment', () {
      expect(
        resolve('{series_index:0>2s} - {title}', {
          ...values,
          'series_index': '1',
        }),
        ['01 - The Eye of the World'],
      );
      expect(resolve('{id:0>5s}'), ['00042']);
      expect(resolve('{id:*<5s}'), ['42***']);
    });

    test('formats numbers', () {
      expect(
        resolve('{series_index:05.1f}', {...values, 'series_index': '2.5'}),
        ['002.5'],
      );
      expect(resolve('{id:03d}'), ['042']);
    });

    test('emits prefix and suffix only for non empty fields', () {
      expect(resolve('{series:|| - }{title}'), [
        'The Wheel of Time - The Eye of the World',
      ]);
      expect(resolve('{series:|| - }{title}', {...values, 'series': ''}), [
        'The Eye of the World',
      ]);
    });

    test('resolves the template from issue #192', () {
      const template =
          '{#library}/{author_sort:.20}/'
          '{series:|| - }{series_index:0>2s|| - }{title:.15}';

      expect(resolve(template, {...values, '#library': 'Manuals'}), [
        'Manuals',
        'Jordan, Robert',
        'The Wheel of Time - 01 - The Eye of the',
      ]);
    });

    test('never pads an empty field into a value', () {
      const template =
          '{author_sort:.20}/'
          '{series:|| - }{series_index:0>2s|| - }{title:.15}';

      expect(resolve(template, {...values, 'series': '', 'series_index': ''}), [
        'Jordan, Robert',
        'The Eye of the',
      ]);
    });

    test('drops folders for custom columns without a value', () {
      const template = '{#library}/{author_sort:.20}/{title:.15}';

      expect(resolve(template), ['Jordan, Robert', 'The Eye of the']);
    });

    test('leaves values untouched for unsupported calibre functions', () {
      expect(resolve('{title:re(The,A)}'), ['The Eye of the World']);
    });

    test('caps overly long segments', () {
      final longTitle = 'A' * 300;
      expect(
        resolve('{title}', {...values, 'title': longTitle}).single.length,
        DownloadPathTemplate.maxSegmentLength,
      );
    });
  });

  group('custom columns', () {
    test('collects the custom column fields of a template', () {
      expect(
        DownloadPathTemplate.customColumnFields('{#My Library}/{#shelf-name}'),
        {'#my_library', '#shelf_name'},
      );
      expect(
        DownloadPathTemplate.customColumnFields('{author}/{title}'),
        isEmpty,
      );
    });

    test('normalizes display names to calibre labels', () {
      expect(
        DownloadPathTemplate.normalizeCustomField('My Library'),
        '#my_library',
      );
      expect(DownloadPathTemplate.normalizeCustomField('#library'), '#library');
    });
  });

  group('file names', () {
    test('removes dots so the mime type stays detectable', () {
      expect(
        DownloadPathTemplate.sanitizeFileName('Vol. 1 - Dr. No'),
        'Vol 1 - Dr No',
      );
    });

    test('preview keeps the extension detectable', () {
      expect(
        DownloadPathTemplate.preview('{author}/{title:.7}.{id}'),
        '/Robert Jordan/The Eye 42.epub',
      );
    });

    test('preview shows the label of a custom column', () {
      expect(
        DownloadPathTemplate.preview('{#library}/{title}'),
        '/library/The Eye of the World.epub',
      );
    });
  });

  group('DownloadPathTemplate helpers', () {
    test('pads whole series indices', () {
      expect(DownloadPathTemplate.formatSeriesIndex(1), '01');
      expect(DownloadPathTemplate.formatSeriesIndex(10), '10');
      expect(DownloadPathTemplate.formatSeriesIndex(1.5), '1.5');
      expect(DownloadPathTemplate.formatSeriesIndex(0), '');
    });

    test('extracts the year from a pubdate', () {
      expect(
        DownloadPathTemplate.yearFromPubdate('1990-01-15T00:00:00+00:00'),
        '1990',
      );
      expect(DownloadPathTemplate.yearFromPubdate(''), '');
      expect(DownloadPathTemplate.yearFromPubdate('unknown'), '');
    });

    test('preview renders a full example path', () {
      expect(
        DownloadPathTemplate.preview('{author}/{series}/{title}'),
        '/Robert Jordan/The Wheel of Time/The Eye of the World.epub',
      );
    });
  });
}
