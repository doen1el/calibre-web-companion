import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';

class BookCardWidget extends StatefulWidget {
  final DownloadServiceBookModel book;
  final bool isSearchResult;

  const BookCardWidget({
    super.key,
    required this.book,
    required this.isSearchResult,
  });

  @override
  State<BookCardWidget> createState() => _BookCardWidgetState();
}

class _BookCardWidgetState extends State<BookCardWidget> {
  late Future<Map<String, dynamic>> _imageContextFuture;

  @override
  void initState() {
    super.initState();
    _imageContextFuture = _getImageContext();
  }

  Future<Map<String, dynamic>> _getImageContext() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('downloader_cookie');
    final baseUrl = prefs.getString('downloader_url') ?? '';

    final headers = <String, String>{};
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    return {'headers': headers, 'baseUrl': baseUrl};
  }

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
                          widget.book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          Icons.person,
                          widget.book.author,
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          context,
                          Icons.business,
                          widget.book.publisher,
                          Theme.of(context).colorScheme.secondary,
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        if (widget.book.year != '') ...[
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            widget.book.year.toString(),
                            Theme.of(context).colorScheme.secondary,
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                        ],
                        _buildInfoBadges(context),
                        if (!widget.isSearchResult &&
                            widget.book.status !=
                                DownloaderStatus.notDownloaded) ...[
                          const SizedBox(height: 8),
                          _buildStatusIndicator(context, localizations),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!widget.isSearchResult &&
                widget.book.status == DownloaderStatus.error &&
                widget.book.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  '${localizations.error}: ${widget.book.errorMessage}',
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
            widget.book.preview.isNotEmpty
                ? FutureBuilder<Map<String, dynamic>>(
                  future: _imageContextFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: .3),
                        child: Skeletonizer(
                          enabled: true,
                          child: const SizedBox(),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    final headers = data['headers'] as Map<String, String>;
                    final baseUrl = data['baseUrl'] as String;

                    String imageUrl = widget.book.preview;

                    imageUrl = '$baseUrl$imageUrl';

                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: headers,
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
                          (context, url, error) =>
                              _buildCoverPlaceholder(context),
                      maxWidthDiskCache: 120,
                      maxHeightDiskCache: 180,
                    );
                  },
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
        if (widget.book.format.isNotEmpty)
          _buildInfoBadge(
            context,
            widget.book.format.toUpperCase(),
            color: Theme.of(context).colorScheme.primaryContainer,
            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        if (widget.book.size.isNotEmpty)
          _buildInfoBadge(
            context,
            widget.book.size,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        if (widget.book.language.isNotEmpty)
          _buildInfoBadge(
            context,
            widget.book.language.toUpperCase(),
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

    switch (widget.book.status) {
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

    if (widget.isSearchResult) {
      final bool isLoadingThisBook = state.isBookDownloading(widget.book.id);

      buttons.add(
        ElevatedButton(
          onPressed:
              isLoadingThisBook
                  ? null
                  : () async {
                    context.read<DownloadServiceBloc>().add(
                      DownloadBook(widget.book.id),
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
      switch (widget.book.status) {
        case DownloaderStatus.error:
          final bool isLoadingThisBook = state.isBookDownloading(
            widget.book.id,
          );

          buttons.add(
            ElevatedButton.icon(
              onPressed:
                  isLoadingThisBook
                      ? null
                      : () => context.read<DownloadServiceBloc>().add(
                        DownloadBook(widget.book.id),
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
