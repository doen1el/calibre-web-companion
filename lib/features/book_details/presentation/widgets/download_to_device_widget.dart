import 'dart:io';
import 'package:calibre_web_companion/shared/widgets/coming_soon_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';

class DownloadToDeviceWidget extends StatelessWidget {
  final BookDetailsModel book;
  final bool isLoading;

  const DownloadToDeviceWidget({
    super.key,
    required this.book,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<BookDetailsBloc, BookDetailsState>(
      buildWhen:
          (previous, current) =>
              previous.downloadState != current.downloadState ||
              previous.downloadProgress != current.downloadProgress,
      builder: (context, state) {
        return IconButton(
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child:
                state.downloadState == DownloadState.downloading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value:
                            state.downloadProgress > 0
                                ? state.downloadProgress / 100
                                : null,
                      ),
                    )
                    : const Icon(Icons.download_rounded),
          ),
          onPressed:
              isLoading || state.downloadState == DownloadState.downloading
                  ? null
                  : () => _showDownloadOptions(context, localizations, book),
          tooltip: localizations.downloadToDevice,
        );
      },
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
  ) {
    // TODO: Implement the download feature with the media storage API
    showComingSoonDialog(context, "The download feature is coming soon!");
    // if (book.formats.length == 1) {
    //   _downloadBook(
    //     context,
    //     localizations,
    //     book,
    //     book.formats.first.toLowerCase(),
    //   );
    //   return;
    // }

    // showModalBottomSheet(
    //   context: context,
    //   builder:
    //       (context) => SafeArea(
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             ListTile(
    //               title: Text(localizations.downlaodFomat),
    //               leading: const Icon(Icons.download),
    //             ),
    //             const Divider(),
    //             ...book.formats.map((format) {
    //               IconData icon;
    //               switch (format.toLowerCase()) {
    //                 case 'epub':
    //                   icon = Icons.menu_book;
    //                   break;
    //                 case 'pdf':
    //                   icon = Icons.picture_as_pdf;
    //                   break;
    //                 case 'mobi':
    //                   icon = Icons.book_online;
    //                   break;
    //                 default:
    //                   icon = Icons.file_present;
    //               }

    //               return ListTile(
    //                 leading: Icon(icon),
    //                 title: Text(format.toUpperCase()),
    //                 onTap: () {
    //                   Navigator.pop(context);
    //                   _downloadBook(context, localizations, book, format);
    //                 },
    //               );
    //             }),
    //           ],
    //         ),
    //       ),
    // );
  }

  void _downloadBook(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
    String format,
  ) async {
    _showDownloadStatusSheet(
      context,
      localizations,
      DownloadState.downloading,
      null,
      0,
      () {
        context.read<BookDetailsBloc>().add(CancelDownload());
        Navigator.pop(context);
      },
    );

    final settingsState = context.read<SettingsBloc>().state;
    final schema = settingsState.downloadSchema;

    context.read<BookDetailsBloc>().add(
      DownloadBook(
        bookId: book.id.toString(),
        format: format,
        title: book.title,
        author: book.authors,
        series: book.series,
        seriesIndex: book.seriesIndex,
        schema: schema,
      ),
    );
  }

  void _showDownloadStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
    DownloadState initialStatus,
    String? errorMessage,
    int initialProgress,
    VoidCallback? onCancel,
  ) {
    final BuildContext outerContext = context;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: BlocProvider.value(
            value: BlocProvider.of<BookDetailsBloc>(outerContext),
            child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
              listenWhen: (previous, current) {
                return previous.downloadState != current.downloadState ||
                    previous.downloadErrorMessage !=
                        current.downloadErrorMessage;
              },
              listener: (context, state) {
                if (state.downloadState == DownloadState.success ||
                    state.downloadState == DownloadState.failed) {}
              },
              buildWhen: (previous, current) {
                return previous.downloadState != current.downloadState ||
                    previous.downloadProgress != current.downloadProgress ||
                    previous.downloadErrorMessage !=
                        current.downloadErrorMessage;
              },
              builder: (context, state) {
                final currentStatus =
                    state.downloadState != DownloadState.initial
                        ? state.downloadState
                        : initialStatus;
                final currentError =
                    state.downloadErrorMessage?.isNotEmpty == true
                        ? state.downloadErrorMessage
                        : errorMessage;
                final currentProgress =
                    state.downloadState == DownloadState.downloading
                        ? state.downloadProgress
                        : initialProgress;

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusIcon(currentStatus, context),
                        const SizedBox(height: 20),

                        Text(
                          _getStatusMessage(currentStatus, localizations),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (currentError != null &&
                            currentStatus == DownloadState.failed)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              currentError,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 20),

                        if (currentStatus == DownloadState.selectingDestination)
                          LinearProgressIndicator(
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),

                        if (currentStatus == DownloadState.downloading)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                backgroundColor: Colors.grey[200],
                                value:
                                    currentProgress > 0
                                        ? currentProgress / 100
                                        : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$currentProgress%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Material(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () {
                                if (currentStatus == DownloadState.initial ||
                                    currentStatus ==
                                        DownloadState.selectingDestination ||
                                    currentStatus ==
                                        DownloadState.downloading) {
                                  if (onCancel != null) onCancel();
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      currentStatus == DownloadState.success ||
                                              currentStatus ==
                                                  DownloadState.failed
                                          ? Icons.close
                                          : Icons.cancel_rounded,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      currentStatus == DownloadState.success ||
                                              currentStatus ==
                                                  DownloadState.failed
                                          ? localizations.close
                                          : localizations.cancel,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

Widget _buildStatusIcon(DownloadState status, BuildContext context) {
  switch (status) {
    case DownloadState.initial:
      return const CircularProgressIndicator();
    case DownloadState.selectingDestination:
      return const Icon(Icons.folder_open_rounded, size: 48);
    case DownloadState.downloading:
      return const Icon(Icons.download_rounded, size: 48);
    case DownloadState.success:
      return Icon(
        Icons.check_circle,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      );
    case DownloadState.failed:
      return Icon(
        Icons.error_outline,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      );
    case DownloadState.canceled:
      return Icon(
        Icons.cancel_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.secondary,
      );
  }
}

String _getStatusMessage(DownloadState status, AppLocalizations localizations) {
  switch (status) {
    case DownloadState.initial:
      return localizations.preparingDownload;
    case DownloadState.selectingDestination:
      return localizations.selectDownloadDestination;
    case DownloadState.downloading:
      return localizations.downloadingBook;
    case DownloadState.success:
      return localizations.successfullyDownloadedBook;
    case DownloadState.failed:
      return localizations.downloadFailed;
    case DownloadState.canceled:
      return localizations.downloadCancelled;
  }
}
