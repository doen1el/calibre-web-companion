import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/reader/data/page_progress_store.dart';
import 'package:calibre_web_companion/features/reader/presentation/pages/comic_reader_page.dart';
import 'package:calibre_web_companion/features/reader/presentation/pages/pdf_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Opens a PDF or CBZ in the matching in-app reader and returns how far the
// reader got, in percent.
Future<double?> openPageReader(
  BuildContext context, {
  required Uint8List bytes,
  required String format,
  required String bookUuid,
  required String title,
  void Function(int page, int pageCount)? onPageChanged,
}) async {
  final store = PageProgressStore(
    prefs: GetIt.instance<SharedPreferences>(),
    logger: GetIt.instance<Logger>(),
  );
  final start = await store.load(bookUuid, format);
  if (!context.mounted) return null;

  void handlePage(int page, int pageCount) {
    store.saveLocal(
      bookUuid,
      format,
      PageProgress(
        page: page,
        pageCount: pageCount,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    onPageChanged?.call(page, pageCount);
  }

  final initialPage = start?.page ?? 0;
  final Widget page =
      format.toLowerCase() == 'pdf'
          ? PdfReaderPage(
            bytes: bytes,
            title: title,
            initialPage: initialPage,
            onPageChanged: handlePage,
          )
          : ComicReaderPage(
            bytes: bytes,
            title: title,
            initialPage: initialPage,
            onPageChanged: handlePage,
          );

  await Navigator.of(context).push(AppTransitions.createSlideRoute(page));

  await store.push(bookUuid, format);
  return store.local(bookUuid, format)?.percentage;
}
