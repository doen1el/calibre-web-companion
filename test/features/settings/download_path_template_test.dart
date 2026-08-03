import 'package:flutter_test/flutter_test.dart';

import 'package:calibre_web_companion/features/settings/data/models/download_path_template.dart';

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
