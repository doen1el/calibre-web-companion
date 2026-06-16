import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';

enum _ItemState { idle, downloading, queued, error }

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

  final Map<String, _ItemState> _states = {};

  Map<String, String> _coverHeaders = const {};
  String _coverBaseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCoverContext();
    _search();
  }

  Future<void> _loadCoverContext() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('downloader_cookie');
    if (!mounted) return;
    setState(() {
      _coverBaseUrl = prefs.getString('downloader_url') ?? '';
      _coverHeaders = {
        if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      };
    });
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
    setState(() => _states[book.id] = _ItemState.downloading);
    try {
      await widget.repository.downloadBook(book);
      if (!mounted) return;
      setState(() => _states[book.id] = _ItemState.queued);
      context.showSnackBar(localizations.downloadStarted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _states[book.id] = _ItemState.error);
      context.showSnackBar(localizations.downloadFailed, isError: true);
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
                  Expanded(
                    child: Text(
                      widget.book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildResultCard(context, localizations, _results[index]);
      },
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    AppLocalizations localizations,
    DownloadServiceBookModel book,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(context, book),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (book.author.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildBadges(context, book),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildAction(context, localizations, book),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, DownloadServiceBookModel book) {
    const width = 56.0;
    const height = 80.0;
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child:
          book.preview.isEmpty
              ? placeholder
              : CachedNetworkImage(
                imageUrl: '$_coverBaseUrl${book.preview}',
                httpHeaders: _coverHeaders,
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
    );
  }

  Widget _buildBadges(BuildContext context, DownloadServiceBookModel book) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (book.format.isNotEmpty)
          _badge(
            context,
            book.format.toUpperCase(),
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          ),
        if (book.size.isNotEmpty)
          _badge(
            context,
            book.size,
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
          ),
        if (book.language.isNotEmpty)
          _badge(
            context,
            book.language.toUpperCase(),
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
          ),
      ],
    );
  }

  Widget _badge(
    BuildContext context,
    String text,
    Color color,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    AppLocalizations localizations,
    DownloadServiceBookModel book,
  ) {
    final theme = Theme.of(context);
    final state = _states[book.id] ?? _ItemState.idle;

    switch (state) {
      case _ItemState.downloading:
        return FilledButton.tonalIcon(
          onPressed: null,
          icon: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text(localizations.downloading),
        );
      case _ItemState.queued:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              localizations.queued,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _ItemState.error:
        return ElevatedButton.icon(
          onPressed: () => _download(book),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(localizations.retry),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
        );
      case _ItemState.idle:
        return FilledButton.tonalIcon(
          onPressed: () => _download(book),
          icon: const Icon(Icons.download_rounded),
          label: Text(localizations.download),
        );
    }
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
