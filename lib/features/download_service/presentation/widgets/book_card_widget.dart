import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';

class BookCardWidget extends StatelessWidget {
  final DownloadServiceBookModel book;
  final bool isSearchResult;

  const BookCardWidget({
    super.key,
    required this.book,
    required this.isSearchResult,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookCover(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          Icons.person,
                          book.author,
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          context,
                          Icons.business,
                          book.publisher,
                          Theme.of(context).colorScheme.secondary,
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        if (book.year > 0) ...[
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            book.year.toString(),
                            Theme.of(context).colorScheme.secondary,
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                        ],
                        _buildInfoBadges(context),
                        if (!isSearchResult &&
                            book.status != DownloaderStatus.notDownloaded) ...[
                          const SizedBox(height: 8),
                          _buildStatusIndicator(context, localizations),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isSearchResult &&
                book.status == DownloaderStatus.error &&
                book.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  '${localizations.error}: ${book.errorMessage}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(context, localizations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        bottomLeft: Radius.circular(0.0),
      ),
      child: SizedBox(
        width: 120,
        height: 180,
        child:
            book.preview.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: book.preview,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: .3),
                        child: Skeletonizer(
                          enabled: true,
                          effect: ShimmerEffect(
                            baseColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            highlightColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .4),
                          ),
                          child: const SizedBox(),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => _buildCoverPlaceholder(context),
                  maxWidthDiskCache: 120,
                  maxHeightDiskCache: 180,
                )
                : _buildCoverPlaceholder(context),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    Color iconColor, {
    TextStyle? textStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (book.format.isNotEmpty)
          _buildInfoBadge(
            context,
            book.format.toUpperCase(),
            color: Theme.of(context).colorScheme.primaryContainer,
            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        if (book.size.isNotEmpty)
          _buildInfoBadge(
            context,
            book.size,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        if (book.language.isNotEmpty)
          _buildInfoBadge(
            context,
            book.language.toUpperCase(),
            color: Theme.of(context).colorScheme.secondaryContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
      ],
    );
  }

  Widget _buildInfoBadge(
    BuildContext context,
    String text, {
    required Color color,
    required Color textColor,
  }) {
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

  Widget _buildStatusIndicator(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (book.status) {
      case DownloaderStatus.available:
        statusColor = Colors.blue;
        statusIcon = Icons.download_rounded;
        statusText = localizations.available;
        break;
      case DownloaderStatus.downloading:
        statusColor = Colors.amber;
        statusIcon = Icons.downloading_rounded;
        statusText = localizations.downloading;
        break;
      case DownloaderStatus.done:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        statusText = localizations.completed;
        break;
      case DownloaderStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        statusText = localizations.failed;
        break;
      case DownloaderStatus.queued:
        statusColor = Colors.purple;
        statusIcon = Icons.queue_rounded;
        statusText = localizations.queued;
        break;
      case DownloaderStatus.notDownloaded:
        statusColor = Colors.grey;
        statusIcon = Icons.download_rounded;
        statusText = localizations.notDownloaded;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final buttons = <Widget>[];
    final state = context.watch<DownloadServiceBloc>().state;

    if (isSearchResult) {
      final bool isLoadingThisBook = state.isBookDownloading(book.id);

      buttons.add(
        ElevatedButton(
          onPressed:
              isLoadingThisBook
                  ? null
                  : () async {
                    context.read<DownloadServiceBloc>().add(
                      DownloadBook(book.id),
                    );
                    context.showSnackBar(
                      localizations.addedBookToTheDownloadQueue,
                      isError: false,
                    );
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
          child:
              isLoadingThisBook
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSecondary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.loading,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    localizations.download,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
        ),
      );
    } else {
      switch (book.status) {
        case DownloaderStatus.error:
          final bool isLoadingThisBook = state.isBookDownloading(book.id);

          buttons.add(
            ElevatedButton.icon(
              onPressed:
                  isLoadingThisBook
                      ? null
                      : () => context.read<DownloadServiceBloc>().add(
                        DownloadBook(book.id),
                      ),
              icon:
                  isLoadingThisBook
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onError,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.onError,
                      ),
              label: Text(
                localizations.retry,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          );
          break;
        default:
          break;
      }
    }

    return buttons;
  }
}
