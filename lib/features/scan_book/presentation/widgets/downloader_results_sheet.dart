import 'package:flutter/material.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';

class DownloaderResultsSheet extends StatefulWidget {
  final IsbnBook book;
  final DownloadServiceRepository repository;

  const DownloaderResultsSheet({
    super.key,
    required this.book,
    required this.repository,
  });

  @override
  State<DownloaderResultsSheet> createState() => _DownloaderResultsSheetState();
}

class _DownloaderResultsSheetState extends State<DownloaderResultsSheet> {
  bool _isLoading = true;
  String? _error;
  List<DownloadServiceBookModel> _results = const [];
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.getSavedFilterSettings();
      final filter = saved.copyWith(isbn: widget.book.isbn);
      final results = await widget.repository.searchBooks(
        _searchQuery(widget.book),
        filter: filter,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _searchQuery(IsbnBook book) {
    if (book.title.isEmpty) return book.isbn;
    final simplified = book.title.split(':').first.split('(').first.trim();
    return simplified.isEmpty ? book.title : simplified;
  }

  Future<void> _download(DownloadServiceBookModel book) async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _downloading.add(book.id));
    try {
      await widget.repository.downloadBook(book);
      if (!mounted) return;
      context.showSnackBar(localizations.downloadStarted);
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(localizations.downloadFailed, isError: true);
    } finally {
      if (mounted) setState(() => _downloading.remove(book.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_download_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Expanded(
                      child: Text(
                        widget.book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(context, localizations, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations localizations,
    ScrollController scrollController,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(localizations.searchingDownloader),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildEmptyState(
        context,
        Icons.error_outline_rounded,
        localizations.downloadFailed,
        onRetry: _search,
        retryLabel: localizations.scanAgain,
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.search_off_rounded,
        localizations.noDownloaderResults,
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = _results[index];
        final isDownloading = _downloading.contains(book.id);
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                book.author,
                book.format.toUpperCase(),
                book.size,
                book.language.toUpperCase(),
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
            trailing:
                isDownloading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: localizations.download,
                      onPressed: () => _download(book),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String message, {
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? message),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
