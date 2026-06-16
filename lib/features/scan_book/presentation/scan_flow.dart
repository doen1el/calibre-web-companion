import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/isbn_remote_datasource.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/widgets/scan_result_sheet.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

final Logger _logger = Logger();

Future<bool> isDownloaderConfigured() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getString('downloader_url') ?? '').isNotEmpty;
}

Future<String?> promptForIsbn(BuildContext context, {String? initial}) {
  final localizations = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(localizations.enterIsbn),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: localizations.isbn,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.cancel),
          ),
          AppDialogButton(
            label: localizations.search,
            icon: Icons.search,
            onPressed:
                () => Navigator.of(dialogContext).pop(controller.text.trim()),
          ),
        ],
      );
    },
  );
}

Future<bool> runIsbnLookupFlow(BuildContext context, String isbn) async {
  final source = IsbnRemoteDataSource();
  var currentIsbn = isbn;

  while (true) {
    if (!context.mounted) return false;
    final book = await _lookupWithProgress(context, source, currentIsbn);
    if (!context.mounted) return false;

    if (book != null) {
      final downloaderConfigured = await isDownloaderConfigured();
      if (!context.mounted) return false;
      final added = await showScanResultSheet(
        context,
        book: book,
        downloaderConfigured: downloaderConfigured,
      );
      return added == true;
    }

    final retryIsbn = await _notFoundDialog(context, currentIsbn);
    if (retryIsbn == null || retryIsbn.isEmpty) return false;
    currentIsbn = retryIsbn;
  }
}

Future<IsbnBook?> _lookupWithProgress(
  BuildContext context,
  IsbnRemoteDataSource source,
  String isbn,
) async {
  final localizations = AppLocalizations.of(context)!;
  _logger.i('Manual ISBN flow: looking up $isbn');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 20),
                Flexible(child: Text(localizations.lookingUpBook)),
              ],
            ),
          ),
        ),
  );

  IsbnBook? book;
  try {
    book = await source.lookupByIsbn(isbn);
  } catch (e) {
    _logger.e('Manual ISBN lookup failed for $isbn: $e');
    if (context.mounted) {
      Navigator.of(context).pop();
      context.showSnackBar(localizations.isbnLookupFailed, isError: true);
    }
    return null;
  }

  if (context.mounted) {
    Navigator.of(context).pop();
  }
  return book;
}

Future<String?> _notFoundDialog(BuildContext context, String isbn) async {
  final localizations = AppLocalizations.of(context)!;
  final wantsEdit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(localizations.isbnNotFound),
        content: Text('ISBN: $isbn'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          AppDialogButton(
            label: localizations.editIsbn,
            icon: Icons.edit_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );

  if (wantsEdit != true || !context.mounted) return null;
  return promptForIsbn(context, initial: isbn);
}
