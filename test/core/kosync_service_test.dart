import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:cosmos_epub/Helpers/progress_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic filler; the digests below were produced by an independent
/// Python implementation of the same sampling the server uses in
/// `cps/progress_syncing/checksums/koreader.py`.
Uint8List pattern(int length) =>
    Uint8List.fromList(List.generate(length, (i) => (i * 37 + 11) % 256));

void main() {
  group('KoSyncService.partialMd5', () {
    test('hashes an empty file as md5 of nothing', () {
      expect(
        KoSyncService.partialMd5(Uint8List(0)),
        'd41d8cd98f00b204e9800998ecf8427e',
      );
    });

    test('matches the server digest for a file below the first sample', () {
      expect(
        KoSyncService.partialMd5(pattern(512)),
        'c54ed4cc823950b069ebbe4bc7fd5265',
      );
    });

    test('matches the server digest at exactly one sample', () {
      expect(
        KoSyncService.partialMd5(pattern(1024)),
        'd4883a545d61557ce12ff4e95350e997',
      );
    });

    test('matches the server digest when the last sample is truncated', () {
      expect(
        KoSyncService.partialMd5(pattern(5000)),
        'bc0a36e392584120c95013be66f97b0b',
      );
    });

    test('matches the server digest across several sample positions', () {
      expect(
        KoSyncService.partialMd5(pattern(70000)),
        'b61b5f4499750f9b6fa1d009cb425cf9',
      );
    });

    test('ignores bytes between the sample positions', () {
      final a = pattern(5000);
      final b = Uint8List.fromList(a);
      // 3000 sits between the 1K and 4K samples, so it must not be hashed.
      b[3000] = (b[3000] + 1) % 256;

      expect(KoSyncService.partialMd5(a), KoSyncService.partialMd5(b));
    });
  });

  group('KoSyncProgress.fromJson', () {
    test('converts the wire fraction to whole percent', () {
      final progress = KoSyncProgress.fromJson({
        'document': 'abc',
        'progress': '/body/DocFragment[12]/body/div/p[3].0',
        'position_kind': 'locator',
        'percentage': 0.4567,
        'device': 'KOReader',
        'timestamp': 1699564800,
        'calibre_book_id': 42,
      });

      expect(progress.percentage, closeTo(45.67, 0.001));
      expect(progress.positionKind, 'locator');
      expect(progress.calibreBookId, 42);
      expect(progress.device, 'KOReader');
    });

    test('keeps a percentage-only row with its null locator', () {
      final progress = KoSyncProgress.fromJson({
        'document': 'abc',
        'progress': null,
        'position_kind': 'percentage',
        'percentage': 0.25,
        'device': 'Web reader',
      });

      expect(progress.progress, isNull);
      expect(progress.positionKind, 'percentage');
      expect(progress.percentage, closeTo(25.0, 0.001));
    });
  });

  group('chapterIndexForPercentage', () {
    test('weights chapters by length instead of counting them', () {
      // A short foreword followed by one long chapter: half the book is deep
      // inside the second chapter, not at the boundary a count-based split
      // would pick.
      expect(chapterIndexForPercentage([100, 900], 50), 1);
      expect(chapterIndexForPercentage([100, 900], 5), 0);
    });

    test('maps the edges onto the first and last chapter', () {
      expect(chapterIndexForPercentage([300, 300, 300], 0), 0);
      expect(chapterIndexForPercentage([300, 300, 300], 100), 2);
    });

    test('clamps out-of-range percentages', () {
      expect(chapterIndexForPercentage([300, 300], -20), 0);
      expect(chapterIndexForPercentage([300, 300], 180), 1);
    });

    test('falls back to an even split without usable weights', () {
      expect(chapterIndexForPercentage([0, 0, 0, 0], 80), 3);
    });

    test('handles an empty book', () {
      expect(chapterIndexForPercentage([], 42), 0);
    });
  });

  group('percentageForPosition', () {
    test('reports the start of a chapter as the content before it', () {
      // Chapter 2 of four equal chapters starts at 25% of the book.
      expect(
        percentageForPosition([250, 250, 250, 250], 1, 0, 10),
        closeTo(25.0, 0.001),
      );
    });

    test('advances within a chapter by its share of the book', () {
      // Halfway through the second of two equal chapters: 50% + half of 50%.
      expect(percentageForPosition([500, 500], 1, 5, 11), closeTo(75.0, 0.001));
    });

    test('weights a long chapter more than a short one', () {
      // Entering the 900-char chapter is 10% in, not 50%.
      expect(percentageForPosition([100, 900], 1, 0, 20), closeTo(10.0, 0.001));
    });

    test('reaches 100% on the last page of the last chapter', () {
      expect(
        percentageForPosition([300, 700], 1, 9, 10),
        closeTo(100.0, 0.001),
      );
    });

    test('round-trips back to the same chapter', () {
      const weights = [120, 800, 340, 90, 600];
      for (var chapter = 0; chapter < weights.length; chapter++) {
        final percentage = percentageForPosition(weights, chapter, 1, 10);
        expect(chapterIndexForPercentage(weights, percentage), chapter);
      }
    });

    test('clamps a chapter index outside the book', () {
      expect(percentageForPosition([500, 500], 9, 0, 1), closeTo(50.0, 0.001));
    });

    test('handles a single-page chapter without dividing by zero', () {
      final percentage = percentageForPosition([500, 500], 1, 0, 1);
      expect(percentage, closeTo(50.0, 0.001));
    });
  });

  group('fractionWithinChapter', () {
    test('is 0 at the start of a chapter', () {
      expect(
        fractionWithinChapter([250, 250, 250, 250], 1, 25),
        closeTo(0, 0.001),
      );
    });

    test('is the share of the chapter already behind the position', () {
      expect(fractionWithinChapter([500, 500], 1, 75), closeTo(0.5, 0.001));
      expect(fractionWithinChapter([100, 900], 1, 55), closeTo(0.5, 0.001));
    });

    test('pairs with the chapter the same percentage resolves to', () {
      const weights = [120, 800, 340, 90, 600];
      const percentage = 63.0;

      final chapter = chapterIndexForPercentage(weights, percentage);
      final fraction = fractionWithinChapter(weights, chapter, percentage);

      expect(fraction, inInclusiveRange(0.0, 1.0));
      // Reading the position back out lands where it started.
      expect(
        percentageForPosition(weights, chapter, (fraction * 100).round(), 101),
        closeTo(percentage, 0.5),
      );
    });

    test('clamps a position outside the chapter', () {
      expect(fractionWithinChapter([500, 500], 0, 90), closeTo(1.0, 0.001));
      expect(fractionWithinChapter([500, 500], 1, 10), closeTo(0.0, 0.001));
    });

    test('returns 0 for an unusable chapter or book', () {
      expect(fractionWithinChapter([], 0, 50), 0);
      expect(fractionWithinChapter([500, 500], 7, 50), 0);
      expect(fractionWithinChapter([0, 0], 1, 50), 0);
    });
  });

  group('pageIndexForFraction', () {
    test('spreads the fraction across the available pages', () {
      expect(pageIndexForFraction(0, 10), 0);
      expect(pageIndexForFraction(0.5, 11), 5);
      expect(pageIndexForFraction(1, 10), 9);
    });

    test('stays on the only page of a one-page chapter', () {
      expect(pageIndexForFraction(0.7, 1), 0);
      expect(pageIndexForFraction(0.7, 0), 0);
    });

    test('clamps a fraction outside 0-1', () {
      expect(pageIndexForFraction(-3, 10), 0);
      expect(pageIndexForFraction(4, 10), 9);
      expect(pageIndexForFraction(double.nan, 10), 0);
    });
  });

  group('KoSyncService.spineStartCfi', () {
    test('addresses the first spine item', () {
      expect(KoSyncService.spineStartCfi(0), 'epubcfi(/6/2!/4)');
    });

    test('takes two steps per spine item', () {
      expect(KoSyncService.spineStartCfi(1), 'epubcfi(/6/4!/4)');
      expect(KoSyncService.spineStartCfi(11), 'epubcfi(/6/24!/4)');
    });
  });
}
