import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/placeholder_book_datasource.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/widgets/downloader_results_sheet.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

Future<bool?> showScanResultSheet(
  BuildContext context, {
  required IsbnBook book,
  required bool downloaderConfigured,
  VoidCallback? onScanAgain,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => ScanResultSheet(
          book: book,
          downloaderConfigured: downloaderConfigured,
          onScanAgain: onScanAgain,
        ),
  );
}

class ScanResultSheet extends StatefulWidget {
  final IsbnBook book;
  final bool downloaderConfigured;
  final VoidCallback? onScanAgain;

  const ScanResultSheet({
    super.key,
    required this.book,
    required this.downloaderConfigured,
    this.onScanAgain,
  });

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  final Logger _logger = Logger();
  bool _adding = false;

  Future<void> _addToCalibre() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _adding = true);
    _logger.i('Adding placeholder book to Calibre: ${widget.book.isbn}');
    try {
      final source = PlaceholderBookDataSource(apiService: getIt<ApiService>());
      await source.createPlaceholder(widget.book);
      if (!mounted) return;
      _logger.i('Placeholder added for ${widget.book.isbn}');
      context.showSnackBar(localizations.bookAddedToCalibre);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _logger.e('Add to Calibre failed: $e');
      setState(() => _adding = false);
      context.showSnackBar(localizations.addToCalibreFailed, isError: true);
    }
  }

  void _openDownloader() {
    _logger.i('Opening downloader from result sheet: ${widget.book.isbn}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => DownloaderResultsSheet(
            book: widget.book,
            repository: getIt<DownloadServiceRepository>(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final book = widget.book;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(theme, book),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title.isEmpty ? book.isbn : book.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (book.authors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          book.authorsLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRows(context, localizations, book),
            if (book.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                localizations.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (book.subjects.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    book.subjects
                        .take(6)
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppDialogButton(
                label: localizations.addToCalibre,
                loadingLabel: localizations.addingToCalibre,
                icon: Icons.library_add_rounded,
                isLoading: _adding,
                onPressed: _adding ? null : _addToCalibre,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      localizations.placeholderEpubHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.downloaderConfigured) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _adding ? null : _openDownloader,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: Text(localizations.downloadFromDownloader),
                ),
              ),
            ],
            if (widget.onScanAgain != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed:
                      _adding
                          ? null
                          : () {
                            Navigator.of(context).pop();
                            widget.onScanAgain!();
                          },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(localizations.scanAgain),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme, IsbnBook book) {
    final placeholder = Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (book.coverUrl == null || book.coverUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        book.coverUrl!,
        width: 90,
        height: 130,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _buildInfoRows(
    BuildContext context,
    AppLocalizations localizations,
    IsbnBook book,
  ) {
    final rows = <Widget>[];
    void add(String label, String value) {
      if (value.isEmpty) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    add(localizations.publisher, book.publisher);
    add(localizations.published, book.publishDate);
    if (book.pageCount != null) {
      add(localizations.pages, '${book.pageCount}');
    }
    add('ISBN', book.isbn);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
