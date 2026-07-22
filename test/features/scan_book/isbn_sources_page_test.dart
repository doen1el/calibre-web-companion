import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_source_settings.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/pages/isbn_sources_page.dart';

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IsbnSourcesPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists every source with the defaults switched on', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(
      find.byType(Switch),
      findsNWidgets(IsbnMetadataSource.values.length),
    );

    final settings = await IsbnSourceSettings.load();
    expect(settings.activeSources, [
      IsbnMetadataSource.openLibrary,
      IsbnMetadataSource.googleBooks,
      IsbnMetadataSource.bnf,
    ]);
  });

  testWidgets('offers the Hardcover token field before it is switched on', (
    tester,
  ) async {
    await _pumpPage(tester);

    final hardcoverCard = find.ancestor(
      of: find.text('Hardcover'),
      matching: find.byType(Card),
    );

    expect(
      find.descendant(of: hardcoverCard, matching: find.byType(TextField)),
      findsOneWidget,
    );
  });

  testWidgets('typing a token enables the source once it is switched on', (
    tester,
  ) async {
    await _pumpPage(tester);

    final hardcoverCard = find.ancestor(
      of: find.text('Hardcover'),
      matching: find.byType(Card),
    );
    await tester.ensureVisible(find.text('Hardcover'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(of: hardcoverCard, matching: find.byType(TextField)),
      'my-token',
    );
    await tester.pumpAndSettle();

    final hardcoverSwitch = find.descendant(
      of: hardcoverCard,
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(hardcoverSwitch);
    await tester.pumpAndSettle();
    await tester.tap(hardcoverSwitch);
    await tester.pumpAndSettle();

    final settings = await IsbnSourceSettings.load();
    expect(settings.credentialFor(IsbnMetadataSource.hardcover), 'my-token');
    expect(settings.activeSources, contains(IsbnMetadataSource.hardcover));
  });

  testWidgets('switching a source off drops it from the lookup', (
    tester,
  ) async {
    await _pumpPage(tester);

    final openLibraryCard = find.ancestor(
      of: find.text('Open Library'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: openLibraryCard, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    final settings = await IsbnSourceSettings.load();
    expect(
      settings.activeSources,
      isNot(contains(IsbnMetadataSource.openLibrary)),
    );
  });

  testWidgets('dragging a card to the top makes it win merges', (tester) async {
    await _pumpPage(tester);

    final handles = find.byIcon(Icons.drag_handle_rounded);
    final start = tester.getCenter(handles.at(2));
    final firstCardTop = tester.getTopLeft(handles.at(0));

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(Offset(0, (firstCardTop.dy - start.dy - 20) / 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final settings = await IsbnSourceSettings.load();
    expect(settings.order.first, IsbnMetadataSource.bnf);
    expect(settings.order.toSet(), IsbnMetadataSource.values.toSet());
  });
}
