import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:calibre_web_companion/core/services/server_capabilities.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_details/data/models/tag_model.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/add_to_shelf_widget.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/download_to_device_widget.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/edit_book_metadata_widget.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/send_to_ereader_widget.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/pages/discover_details_page.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/models/book_details_action.dart';
import 'package:calibre_web_companion/features/settings/data/models/book_details_section.dart';
import 'package:calibre_web_companion/features/settings/presentation/pages/settings_page.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:calibre_web_companion/shared/widgets/app_options_sheet.dart';
import 'package:calibre_web_companion/shared/widgets/app_skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:cosmos_epub/show_epub.dart' as cosmos_reader;
import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum BookAutoOpen { none, internalReader, externalReader }

class BookDetailsPage extends StatefulWidget {
  final BookViewModel bookViewModel;
  final String bookUuid;
  final BookAutoOpen autoOpenAction;

  const BookDetailsPage({
    super.key,
    required this.bookViewModel,
    required this.bookUuid,
    this.autoOpenAction = BookAutoOpen.none,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool _didUpdateMetadata = false;
  bool _didAutoOpen = false;
  int _lastWidgetPercent = -1;
  late final WebDavSyncService _webDavService;
  Timer? _readerProgressTimer;
  int? _koSyncBookId;
  String? _koSyncBookUuid;
  double? _koSyncPercentage;
  int _koSyncSpineIndex = -1;
  double? _koSyncPushedPercentage;
  KoSyncProgress? _koSyncProgress;

  @override
  void dispose() {
    _readerProgressTimer?.cancel();
    super.dispose();
  }

  bool _isInternalReaderSupportedFormat(String format) {
    return format.toLowerCase() == 'epub';
  }

  void _showUnsupportedInternalReaderFormatMessage(
    BuildContext context,
    AppLocalizations localizations,
    List<String> availableFormats,
  ) {
    final formats = availableFormats.map((f) => f.toUpperCase()).join(', ');

    context.showSnackBar(
      localizations.internalReaderSupportsOnlyEpub(formats),
      isError: true,
      duration: const Duration(seconds: 10),
    );
  }

  Future<String?> _selectInternalReaderFormat(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
  ) async {
    final formats =
        book.formats.map((format) => format.toLowerCase()).toSet().toList();

    if (formats.isEmpty) {
      context.showSnackBar(
        localizations.errorOpeningBookInInternalReader,
        isError: true,
      );
      return null;
    }

    final supportedFormats =
        formats.where(_isInternalReaderSupportedFormat).toList();

    if (supportedFormats.isEmpty) {
      _showUnsupportedInternalReaderFormatMessage(
        context,
        localizations,
        formats,
      );
      return null;
    }

    if (formats.length == 1) {
      return supportedFormats.first;
    }

    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppOptionsSheetHeader(title: localizations.downlaodFomat),
                ...formats.map((format) {
                  final isSupported = _isInternalReaderSupportedFormat(format);
                  IconData icon;

                  switch (format) {
                    case 'epub':
                      icon = Icons.menu_book;
                    case 'pdf':
                      icon = Icons.picture_as_pdf;
                    case 'kepub':
                      icon = Icons.book;
                    default:
                      icon = Icons.file_present;
                  }

                  return AppOptionTile(
                    icon: icon,
                    title: format.toUpperCase(),
                    enabled: isSupported,
                    subtitle:
                        isSupported
                            ? null
                            : localizations.internalReaderSupportsOnlyEpubShort,
                    onTap: () => Navigator.pop(sheetContext, format),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _webDavService = WebDavSyncService(logger: GetIt.instance<Logger>());
    _initWebDav();
    _loadKoSyncProgress();
  }

  /// Reads the position other devices reported for this book, for the reading
  /// progress card.
  Future<void> _loadKoSyncProgress() async {
    final koSync = getIt<KoSyncService>();
    if (!await koSync.isEnabled()) return;

    final progress = await koSync.fetchProgress(
      document: widget.bookViewModel.id.toString(),
    );
    if (!mounted || progress == null || progress.percentage <= 0) return;

    setState(() => _koSyncProgress = progress);
  }

  Future<void> _initWebDav() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('webdav_enabled') ?? false;
    if (enabled) {
      _webDavService.init(
        prefs.getString('webdav_url') ?? '',
        prefs.getString('webdav_username') ?? '',
        prefs.getString('webdav_password') ?? '',
        allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
      );
    }
  }

  Future<void> _openInternalReader(
    BuildContext context,
    Uint8List bytes,
    BookDetailsModel bookDetailsModel,
  ) async {
    final localization = AppLocalizations.of(context)!;
    final bookUuid = bookDetailsModel.uuid;

    await _restoreReaderProgressFromCloud(bookUuid);
    if (!context.mounted) return;

    final looksLikeZip =
        bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
    if (!looksLikeZip) {
      if (context.mounted) {
        context.showSnackBar(
          localization.errorOpeningBookInInternalReader,
          isError: true,
        );
      }
      return;
    }

    final startPercentage = await _koSyncStartPercentage(
      context,
      bytes,
      bookDetailsModel,
    );
    if (!context.mounted) return;

    _koSyncBookId = bookDetailsModel.id;
    _koSyncBookUuid = bookUuid;
    _koSyncPercentage = null;
    _koSyncSpineIndex = -1;
    _koSyncPushedPercentage = startPercentage;

    try {
      await CosmosEpub.openFileBook(
        context: context,
        bytes: bytes,
        bookId: bookUuid,
        startPercentage: startPercentage,
        accentColor: Theme.of(context).colorScheme.primary,
        onPageFlip: (currentPage, totalPages) {
          _scheduleReaderProgressSync(bookUuid);
          _pushReadingProgressToWidget(bookUuid, currentPage, totalPages);
        },
        onProgressChanged: (percentage, spineIndex) {
          _koSyncPercentage = percentage;
          _koSyncSpineIndex = spineIndex;
        },
      );
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          '${localization.errorOpeningBookInInternalReader} $e',
          isError: true,
        );
      }
      return;
    }

    _readerProgressTimer?.cancel();
    await _saveReaderProgressToCloud(bookUuid);
    await _pushKoSyncProgress();

    // Re-read rather than reuse what was pushed: the server keeps the furthest
    // position, so a push from behind another device leaves that one standing.
    await _loadKoSyncProgress();
  }

  void _scheduleReaderProgressSync(String bookUuid) {
    _readerProgressTimer?.cancel();
    _readerProgressTimer = Timer(const Duration(seconds: 5), () {
      _saveReaderProgressToCloud(bookUuid);
      _pushKoSyncProgress();
    });
  }

  /// Shares the reader's position with the other devices. Debounced while
  /// reading and run once more when the reader closes.
  Future<void> _pushKoSyncProgress() async {
    final bookId = _koSyncBookId;
    final bookUuid = _koSyncBookUuid;
    final percentage = _koSyncPercentage;
    if (bookId == null || bookUuid == null || percentage == null) return;

    final pushed = _koSyncPushedPercentage;
    if (pushed != null && (pushed - percentage).abs() < 0.1) return;

    final koSync = getIt<KoSyncService>();
    if (!await koSync.isEnabled()) return;

    final ok = await koSync.pushProgress(
      bookId: bookId,
      percentage: percentage,
      spineIndex: _koSyncSpineIndex,
    );
    if (!ok) return;

    _koSyncPushedPercentage = percentage;

    // Our own position must not come back as an offer to jump on next open.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('kosync_applied_$bookUuid', percentage);
  }

  void _pushReadingProgressToWidget(
    String bookUuid,
    int currentPage,
    int totalPages,
  ) {
    if (totalPages <= 0) return;
    final percent = (((currentPage + 1) / totalPages) * 100).round().clamp(
      0,
      100,
    );
    if (percent == _lastWidgetPercent) return;
    _lastWidgetPercent = percent;
    getIt<WidgetService>().updateProgress(bookUuid, percent / 100);
  }

  Future<void> _runAutoOpen(
    BuildContext context,
    BookDetailsState state,
    AppLocalizations localizations,
  ) async {
    final details = state.bookDetails;
    if (details == null) return;

    switch (widget.autoOpenAction) {
      case BookAutoOpen.none:
        return;
      case BookAutoOpen.internalReader:
        final format = await _selectInternalReaderFormat(
          context,
          localizations,
          details,
        );
        if (format == null || !context.mounted) return;
        context.read<BookDetailsBloc>().add(
          OpenBookInInternalReader(book: details, format: format),
        );
        return;
      case BookAutoOpen.externalReader:
        await _triggerExternalReader(context, localizations);
        return;
    }
  }

  Future<void> _triggerExternalReader(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final settingsState = context.read<SettingsBloc>().state;
    DocumentFile? selectedDirectory;

    if (Platform.isAndroid) {
      if (settingsState.defaultDownloadPath.isEmpty) {
        selectedDirectory = await DocMan.pick.directory();
        if (selectedDirectory == null) {
          if (context.mounted) {
            context.showSnackBar(
              localizations.noFolderWasSelected,
              isError: true,
            );
          }
          return;
        }
      } else {
        final uri = settingsState.defaultDownloadPath;
        selectedDirectory =
            uri.isNotEmpty ? await DocumentFile.fromUri(uri) : null;
        if (selectedDirectory == null || !selectedDirectory.isDirectory) {
          if (context.mounted) {
            context.showSnackBar(
              localizations.noFolderWasSelected,
              isError: true,
            );
          }
          return;
        }
      }
    }

    if (!context.mounted) return;
    context.read<BookDetailsBloc>().add(
      OpenBookInReader(
        selectedDirectory: selectedDirectory,
        schema: settingsState.downloadSchema,
        pathTemplate: settingsState.downloadPathTemplate,
      ),
    );
  }

  /// Asks the KOReader sync endpoint where the user is in this book and, if
  /// that is somewhere else than the app last jumped to, offers to follow it.
  Future<double?> _koSyncStartPercentage(
    BuildContext context,
    Uint8List bytes,
    BookDetailsModel book,
  ) async {
    final koSync = getIt<KoSyncService>();
    if (!await koSync.isEnabled()) return null;

    final KoSyncProgress? remote;
    try {
      remote = await koSync.fetchProgress(
        document: KoSyncService.partialMd5(bytes),
        fallbackDocument: book.id.toString(),
      );
    } catch (_) {
      return null;
    }
    if (remote == null || remote.percentage <= 0) return null;

    // Following the same position twice would re-ask on every open and undo
    // reading the app did since, so a position we already applied is done.
    final prefs = await SharedPreferences.getInstance();
    final appliedKey = 'kosync_applied_${book.uuid}';
    final applied = prefs.getDouble(appliedKey);
    if (applied != null && (applied - remote.percentage).abs() < 0.5) {
      return null;
    }

    if (!context.mounted) return null;
    final localization = AppLocalizations.of(context)!;
    final percentage = remote.percentage.toStringAsFixed(0);
    final device = remote.device;

    final follow = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(localization.koSyncContinueTitle),
            content: Text(
              device == null || device.isEmpty
                  ? localization.koSyncContinueBodyUnknownDevice(percentage)
                  : localization.koSyncContinueBody(device, percentage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(localization.koSyncStayHere),
              ),
              AppDialogButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: localization.koSyncJumpThere,
              ),
            ],
          ),
    );

    // Remember it either way: declining once should not mean being asked
    // again on the next open for the same position.
    await prefs.setDouble(appliedKey, remote.percentage);

    return follow == true ? remote.percentage : null;
  }

  Future<void> _restoreReaderProgressFromCloud(String bookUuid) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('webdav_enabled') ?? false)) return;
    final url = prefs.getString('webdav_url') ?? '';
    if (url.isEmpty) return;
    try {
      _webDavService.init(
        url,
        prefs.getString('webdav_username') ?? '',
        prefs.getString('webdav_password') ?? '',
        allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
      );

      final localTs = prefs.getInt('reader_progress_ts_$bookUuid') ?? 0;
      final serverData = await _webDavService.fetchProgress();
      final entry = serverData[bookUuid];
      if (entry is! Map) return;
      final serverTs = (entry['timestamp'] as int?) ?? 0;
      if (serverTs <= localTs) return;

      final decoded = jsonDecode(entry['locator'] as String);
      if (decoded is! Map) return;
      final chapter = decoded['chapter'] as int?;
      final page = decoded['page'] as int?;
      if (chapter != null) {
        await cosmos_reader.bookProgress.setCurrentChapterIndex(
          bookUuid,
          chapter,
        );
      }
      if (page != null) {
        await cosmos_reader.bookProgress.setCurrentPageIndex(bookUuid, page);
      }
      await prefs.setInt('reader_progress_ts_$bookUuid', serverTs);
    } catch (_) {}
  }

  Future<void> _saveReaderProgressToCloud(String bookUuid) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('webdav_enabled') ?? false)) return;
    final url = prefs.getString('webdav_url') ?? '';
    if (url.isEmpty) return;
    try {
      _webDavService.init(
        url,
        prefs.getString('webdav_username') ?? '',
        prefs.getString('webdav_password') ?? '',
        allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
      );

      final progress = cosmos_reader.bookProgress.getBookProgress(bookUuid);
      final now = DateTime.now().millisecondsSinceEpoch;
      final locator = jsonEncode({
        'chapter': progress.currentChapterIndex ?? 0,
        'page': progress.currentPageIndex ?? 0,
      });
      await _webDavService.saveProgress(bookUuid, locator, now);
      await prefs.setInt('reader_progress_ts_$bookUuid', now);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (mounted) {
          Navigator.of(context).pop(result ?? _didUpdateMetadata);
        }
      },
      child: BlocProvider(
        create:
            (context) =>
                getIt<BookDetailsBloc>()
                  ..add(LoadBookDetails(widget.bookViewModel, widget.bookUuid)),
        child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
          listenWhen:
              (previous, current) =>
                  previous.readStatusState != current.readStatusState ||
                  previous.archiveStatusState != current.archiveStatusState ||
                  previous.deleteBookState != current.deleteBookState ||
                  previous.openInReaderState != current.openInReaderState ||
                  previous.openInInternalReaderState !=
                      current.openInInternalReaderState ||
                  previous.metadataUpdateState != current.metadataUpdateState ||
                  previous.bookDetails != current.bookDetails ||
                  previous.seriesNavigationStatus !=
                      current.seriesNavigationStatus,
          listener: (context, state) {
            if (!_didAutoOpen &&
                widget.autoOpenAction != BookAutoOpen.none &&
                state.status == BookDetailsStatus.loaded &&
                state.bookDetails != null) {
              _didAutoOpen = true;
              _runAutoOpen(context, state, localizations);
            }

            if (state.readStatusState == ReadStatusState.success) {
              _didUpdateMetadata = true;
              context.showSnackBar(
                state.isBookRead
                    ? localizations.markedAsReadSuccessfully
                    : localizations.markedAsUnreadSuccessfully,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            } else if (state.readStatusState == ReadStatusState.error) {
              context.showSnackBar(
                state.isBookRead
                    ? localizations.markedAsReadFailed
                    : localizations.markedAsUnreadFailed,
                isError: true,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            }

            if (state.archiveStatusState == ArchiveStatusState.success) {
              _didUpdateMetadata = true;
              context.showSnackBar(
                state.isBookArchived
                    ? localizations.archivedBookSuccessfully
                    : localizations.unarchivedBookSuccessfully,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            } else if (state.archiveStatusState == ArchiveStatusState.error) {
              context.showSnackBar(
                state.isBookArchived
                    ? localizations.archivedBookFailed
                    : localizations.unarchivedBookFailed,
                isError: true,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            }

            if (state.deleteBookState == DeleteBookState.success) {
              _didUpdateMetadata = true;
              context.showSnackBar(localizations.bookDeletedSuccessfully);
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
              Navigator.of(context).pop(true);
            } else if (state.deleteBookState == DeleteBookState.error) {
              context.showSnackBar(
                localizations.failedToDeleteBook,
                isError: true,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            }

            if (state.openInReaderState == OpenInReaderState.success) {
              context.showSnackBar(
                localizations.bookOpenedExternallySuccessfully,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            } else if (state.openInReaderState == OpenInReaderState.error) {
              context.showSnackBar(
                localizations.openBookExternallyFailed,
                isError: true,
              );
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            }

            if (state.openInInternalReaderState ==
                    OpenInInternalReaderState.success &&
                state.readerBytes != null) {
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());

              _openInternalReader(
                context,
                state.readerBytes!,
                state.bookDetails!,
              );
            }

            if (state.openInInternalReaderState ==
                OpenInInternalReaderState.error) {
              context.showSnackBar(
                '${localizations.errorOpeningBookInInternalReader} ${state.errorMessage}',
                isError: true,
              );
            }

            if (state.seriesNavigationStatus ==
                    SeriesNavigationStatus.success &&
                state.seriesNavigationPath != null) {
              Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  DiscoverDetailsPage(
                    title: state.bookDetails?.series ?? '',
                    categoryType: CategoryType.series,
                    fullPath: state.seriesNavigationPath!,
                  ),
                ),
              );
            }

            if (state.seriesNavigationStatus == SeriesNavigationStatus.error) {
              context.showSnackBar(
                localizations.errorLoadingData,
                isError: true,
              );
            }

            if (state.metadataUpdateState == MetadataUpdateState.success) {
              _didUpdateMetadata = true;

              context.showSnackBar(localizations.metadataUpdateSuccessfully);
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());
            }
          },
          buildWhen:
              (previous, current) =>
                  previous.status != current.status ||
                  previous.bookDetails != current.bookDetails ||
                  previous.isBookRead != current.isBookRead ||
                  previous.isBookArchived != current.isBookArchived ||
                  previous.deleteBookState != current.deleteBookState ||
                  previous.openInReaderState != current.openInReaderState ||
                  previous.openInInternalReaderState !=
                      current.openInInternalReaderState ||
                  previous.metadataUpdateState != current.metadataUpdateState ||
                  (previous.metadataUpdateState ==
                          MetadataUpdateState.success &&
                      current.metadataUpdateState ==
                          MetadataUpdateState.success),
          builder: (context, state) {
            final isLoading = state.status == BookDetailsStatus.loading;
            final hasError = state.status == BookDetailsStatus.error;

            if (hasError) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(localizations.error),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed:
                        () => Navigator.of(context).pop(_didUpdateMetadata),
                  ),
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 80,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          localizations.errorLoadingData,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.bookDetailsCouldNotBeLoaded,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: .3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withValues(alpha: .5),
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            iconColor: Theme.of(context).colorScheme.error,
                            collapsedIconColor:
                                Theme.of(context).colorScheme.error,
                            title: Text(
                              localizations.technicalDetails,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SelectableText(
                                  state.errorMessage ?? 'Unknown Error',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pop(_didUpdateMetadata),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(localizations.goBack),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: () {
                                context.read<BookDetailsBloc>().add(
                                  ReloadBookDetails(
                                    state.bookViewModel ?? widget.bookViewModel,
                                    widget.bookUuid,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(localizations.tryAgain),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final book = state.bookDetails ?? _createDummyBook(localizations);

            return Scaffold(
              appBar: AppBar(
                title:
                    isLoading
                        ? AppSkeletonizer(
                          enabled: true,
                          effect: ShimmerEffect(
                            baseColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .2),
                            highlightColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .4),
                          ),
                          child: Container(
                            height: 20,
                            width: 300,
                            color: Colors.black,
                          ),
                        )
                        : Text(
                          book.title.length > 30
                              ? '${book.title.substring(0, 30)}...'
                              : book.title,
                        ),
                leading: IconButton(
                  onPressed:
                      () => Navigator.of(context).pop(_didUpdateMetadata),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  context.read<BookDetailsBloc>().add(
                    ReloadBookDetails(
                      state.bookViewModel ?? widget.bookViewModel,
                      widget.bookUuid,
                    ),
                  );
                },

                child: AppSkeletonizer(
                  enabled: isLoading,
                  effect: ShimmerEffect(
                    baseColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .2),
                    highlightColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .4),
                  ),
                  child: _buildBookDetails(
                    context,
                    localizations,
                    state,
                    book,
                    isLoading,
                  ),
                ),
              ),
              floatingActionButton:
                  isLoading
                      ? null
                      : SendToEreaderWidget(book: book, isLoading: isLoading),
            );
          },
        ),
      ),
    );
  }

  BookDetailsModel _createDummyBook(AppLocalizations localizations) {
    return BookDetailsModel(
      id: widget.bookViewModel.id,
      uuid: widget.bookViewModel.uuid,
      title: widget.bookViewModel.title,
      authors: widget.bookViewModel.authors,
      cover: widget.bookViewModel.coverUrl ?? '',
      formats: widget.bookViewModel.formats,
      tags: widget.bookViewModel.tags,
    );
  }

  Widget _buildBookDetails(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsState state,
    BookDetailsModel book,
    bool isLoading,
  ) {
    final settingsState = context.select((SettingsBloc bloc) => bloc.state);
    final orderedSectionKeys = BookDetailsSectionConfig.normalizeOrder(
      settingsState.bookDetailsSectionsOrder,
    );
    final enabledSections =
        BookDetailsSectionConfig.normalizeEnabled(
          settingsState.enabledBookDetailsSections,
        ).toSet();

    final sectionBuilders = <String, Widget Function()>{
      BookDetailsSection.bookActions.key: () {
        final actions = _buildBookActions(
          context,
          localizations,
          state,
          book,
          isLoading,
        );

        if (actions is SizedBox) {
          return const SizedBox.shrink();
        }

        return _buildCard(
          context,
          Icons.menu_book_rounded,
          localizations.bookActions,
          actions,
        );
      },
      BookDetailsSection.readingProgress.key:
          () => _buildReadingProgressSection(context, localizations),
      BookDetailsSection.rating.key:
          () =>
              book.rating > 0
                  ? _buildCard(
                    context,
                    Icons.star_rate_rounded,
                    localizations.rating,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildRating(book.rating),
                    ),
                  )
                  : const SizedBox.shrink(),
      BookDetailsSection.series.key:
          () =>
              book.series.isNotEmpty
                  ? _buildCard(
                    context,
                    Icons.bookmark_rounded,
                    localizations.series,
                    InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: () {
                        context.read<BookDetailsBloc>().add(
                          OpenSeries(book.series),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 4.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${book.series} (${localizations.book} ${book.seriesIndexLabel})',
                            ),
                            if (state.seriesNavigationStatus ==
                                SeriesNavigationStatus.loading)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
      BookDetailsSection.publicationInfo.key:
          () => _buildInfoCard(
            context,
            Icons.info_outline_rounded,
            localizations.publicationInfo,
            [
              if (book.pubdate != '')
                _buildInfoRow(
                  context,
                  localizations.updated,
                  intl.DateFormat.yMMMMd(
                    localizations.localeName,
                  ).format(DateTime.parse(book.pubdate)),
                  Icons.update_rounded,
                ),
              if (book.publishers != '')
                _buildInfoRow(
                  context,
                  localizations.publisher,
                  book.publishers,
                  Icons.business_rounded,
                ),
              if (book.languages.isNotEmpty)
                _buildInfoRow(
                  context,
                  localizations.language,
                  _formatLanguage(book.languages, localizations),
                  Icons.language_rounded,
                ),
            ],
          ),
      BookDetailsSection.fileInfo.key:
          () => _buildInfoCard(
            context,
            Icons.description_rounded,
            localizations.fileInfo,
            [
              if (book.formats.isNotEmpty)
                _buildInfoRow(
                  context,
                  localizations.formats,
                  book.formats.join(', '),
                  Icons.folder_rounded,
                ),
              if (book.formatMetadata.formats.isNotEmpty)
                _buildInfoRow(
                  context,
                  localizations.size,
                  _formatFileSize(
                    book.formatMetadata.formats.entries.first.value.size!,
                  ),
                  Icons.data_usage_rounded,
                ),
              _buildInfoRow(context, 'ID', book.uuid, Icons.tag_rounded),
            ],
          ),
      BookDetailsSection.tags.key:
          () =>
              book.tags.isNotEmpty
                  ? _buildCard(
                    context,
                    Icons.local_offer_rounded,
                    localizations.tags,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildTags(context, book.tags, book.tagModels),
                    ),
                  )
                  : const SizedBox.shrink(),
      BookDetailsSection.description.key:
          () =>
              book.comments.isNotEmpty
                  ? _buildCard(
                    context,
                    Icons.article_rounded,
                    localizations.description,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        book.comments,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
    };

    final visibleSections =
        orderedSectionKeys
            .where(
              (sectionKey) =>
                  enabledSections.contains(sectionKey) &&
                  sectionBuilders.containsKey(sectionKey),
            )
            .map((sectionKey) => sectionBuilders[sectionKey]!())
            .where((widget) => widget is! SizedBox)
            .toList();

    final bodySections =
        visibleSections.isEmpty
            ? <Widget>[
              _buildAllSectionsDisabledFallback(context, localizations),
            ]
            : visibleSections;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 420,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverImage(context, book.id, book.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.by(book.authors),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [...bodySections, const SizedBox(height: 24)],
          ),
        ),
      ],
    );
  }

  Widget _buildAllSectionsDisabledFallback(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            localizations.bookDetailsAllSectionsDisabledTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.bookDetailsAllSectionsDisabledDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  const SettingsPage(
                    initialSubPage: SettingsSubPage.bookDetails,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            label: Text(localizations.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildBookActions(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsState state,
    BookDetailsModel book,
    bool isLoading,
  ) {
    final settingsState = context.select((SettingsBloc bloc) => bloc.state);
    final enabledActionKeys = settingsState.enabledBookActions.toSet();
    final serverType = GetIt.instance<SharedPreferences>().getString(
      'server_type',
    );
    final caps = ServerCapabilities.fromServerType(serverType);

    final actionBuilders = <String, Widget Function()>{
      BookDetailsAction.toggleReadStatus.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.readStatusState == ReadStatusState.loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Icon(
                        state.isBookRead
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
            ),
            onPressed:
                isLoading
                    ? null
                    : () => context.read<BookDetailsBloc>().add(
                      ToggleReadStatus(book.id),
                    ),
            tooltip: localizations.markAsReadUnread,
          ),
      BookDetailsAction.toggleArchiveStatus.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.archiveStatusState == ArchiveStatusState.loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Icon(
                        state.isBookArchived ? Icons.archive : Icons.unarchive,
                      ),
            ),
            onPressed:
                isLoading
                    ? null
                    : () => context.read<BookDetailsBloc>().add(
                      ToggleArchiveStatus(book.id),
                    ),
            tooltip: localizations.archiveUnarchive,
          ),
      BookDetailsAction.editMetadata.key:
          () => EditBookMetadataWidget(
            book: book,
            isLoading: isLoading,
            bookViewModel: state.bookViewModel ?? widget.bookViewModel,
          ),
      BookDetailsAction.addToShelf.key:
          () => AddToShelfWidget(book: book, isLoading: isLoading),
      BookDetailsAction.downloadToDevice.key:
          () => DownloadToDeviceWidget(book: book, isLoading: isLoading),
      BookDetailsAction.openInInternalReader.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.openInInternalReaderState ==
                          OpenInInternalReaderState.loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : const Icon(Icons.menu_book_rounded),
            ),
            onPressed:
                isLoading
                    ? null
                    : () async {
                      final selectedFormat = await _selectInternalReaderFormat(
                        context,
                        localizations,
                        book,
                      );
                      if (selectedFormat == null) {
                        return;
                      }

                      // ignore: use_build_context_synchronously
                      context.read<BookDetailsBloc>().add(
                        OpenBookInInternalReader(
                          book: book,
                          format: selectedFormat,
                        ),
                      );
                    },
            tooltip: localizations.openInInternalReader,
          ),
      BookDetailsAction.openInReader.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.openInReaderState == OpenInReaderState.loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : const Icon(Icons.open_in_new_rounded),
            ),
            onPressed:
                isLoading
                    ? null
                    : () async {
                      DocumentFile? selectedDirectory;

                      if (Platform.isAndroid) {
                        if (settingsState.defaultDownloadPath.isEmpty) {
                          selectedDirectory = await DocMan.pick.directory();
                          if (selectedDirectory == null) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);

                            // ignore: use_build_context_synchronously
                            context.showSnackBar(
                              localizations.noFolderWasSelected,
                              isError: true,
                            );
                            return;
                          }
                        } else {
                          final uri = settingsState.defaultDownloadPath;
                          selectedDirectory =
                              uri.isNotEmpty
                                  ? await DocumentFile.fromUri(uri)
                                  : null;
                          if (selectedDirectory == null ||
                              !selectedDirectory.isDirectory) {
                            // ignore: use_build_context_synchronously
                            context.showSnackBar(
                              localizations.noFolderWasSelected,
                              isError: true,
                            );
                            return;
                          }
                        }
                      }

                      // ignore: use_build_context_synchronously
                      context.read<BookDetailsBloc>().add(
                        OpenBookInReader(
                          selectedDirectory: selectedDirectory,
                          schema: settingsState.downloadSchema,
                          pathTemplate: settingsState.downloadPathTemplate,
                        ),
                      );
                    },
            tooltip: localizations.openInReader,
          ),
      BookDetailsAction.openInBrowser.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.open_in_browser_rounded),
            ),
            onPressed:
                () => context.read<BookDetailsBloc>().add(
                  const OpenBookInBrowser(),
                ),
            tooltip: localizations.openBookInBrowser,
          ),
      BookDetailsAction.deleteBook.key:
          () => IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child:
                  state.deleteBookState == DeleteBookState.loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Icon(
                        Icons.delete_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
            ),
            onPressed:
                isLoading
                    ? null
                    : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(localizations.deleteBook),
                            content: Text(localizations.deleteBookConfirmation),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text(localizations.cancel),
                              ),
                              AppDialogButton.destructive(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                label: localizations.delete,
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        // ignore: use_build_context_synchronously
                        context.read<BookDetailsBloc>().add(
                          DeleteBook(book.id),
                        );
                      }
                    },
            tooltip: localizations.deleteBook,
          ),
    };

    final unsupportedActions = <String>{
      if (!caps.readingProgress) BookDetailsAction.toggleReadStatus.key,
      if (!caps.readingProgress) BookDetailsAction.toggleArchiveStatus.key,
      if (!caps.editMetadata) BookDetailsAction.editMetadata.key,
      if (!caps.shelves) BookDetailsAction.addToShelf.key,
      if (!caps.deleteBooks) BookDetailsAction.deleteBook.key,
      if (serverType != null && serverType != 'calibreWeb')
        BookDetailsAction.openInBrowser.key,
    };

    final visibleOrder =
        settingsState.bookActionsOrder.where((actionKey) {
          final isEnabled = enabledActionKeys.contains(actionKey);
          final exists = actionBuilders.containsKey(actionKey);
          final isSupported = !unsupportedActions.contains(actionKey);
          return isEnabled && exists && isSupported;
        }).toList();

    if (visibleOrder.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  visibleOrder
                      .map((actionKey) => actionBuilders[actionKey]!())
                      .toList(),
            ),
          ),
        );
      },
    );
  }

  /// Shows up only once a synced position is actually there, so a library
  /// without KOReader sync never grows an empty card.
  Widget _buildReadingProgressSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final progress = _koSyncProgress;
    if (progress == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final percentage = progress.percentage.clamp(0.0, 100.0);
    final timestamp = progress.timestamp;
    final device = progress.device;

    final String? subtitle;
    if (timestamp == null) {
      subtitle = device != null && device.isNotEmpty ? device : null;
    } else {
      final date = intl.DateFormat.yMMMMd(
        localizations.localeName,
      ).add_Hm().format(timestamp.toLocal());
      subtitle =
          device != null && device.isNotEmpty
              ? localizations.koSyncProgressSyncedBy(device, date)
              : localizations.koSyncProgressSyncedOn(date);
    }

    return _buildCard(
      context,
      Icons.timeline_rounded,
      localizations.koSyncProgressTitle,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(0)} %',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget child,
  ) {
    final BorderRadius borderRadius = BorderRadius.circular(12.0);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 4),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    final validChildren = children.where((w) => w is! SizedBox).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      context,
      icon,
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: validChildren,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, [
    IconData? icon,
  ]) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: .7),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatLanguage(String languageCode, AppLocalizations localizations) {
    final languageMap = {
      'eng': localizations.english,
      'deu': localizations.german,
      'fra': localizations.french,
      'spa': localizations.spanish,
      'ita': localizations.italian,
      'jpn': localizations.japanese,
      'rus': localizations.russian,
      'por': localizations.portuguese,
      'chi': localizations.chineese,
      'nld': localizations.dutch,
    };

    return languageMap[languageCode.toLowerCase()] ?? languageCode;
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildCoverImage(BuildContext context, int bookId, String? coverUrl) {
    return SizedBox(
      //height: 350,
      child: BookCoverWidget(bookId: bookId, coverUrl: coverUrl),
    );
  }

  Widget _buildTags(
    BuildContext context,
    List<String> tags,
    List<TagModel> tagModels,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  // Since the book information does not contain the tag IDs, the navigation
                  // to the tag details page is currently disabled.
                  // onTap: () {
                  //   TagModel? tagModel = tagModels.firstWhere(
                  //     (tm) => tm.name == tag,
                  //     orElse: () => TagModel(id: 0, name: tag),
                  //   );
                  //   Navigator.of(context).push(
                  //     AppTransitions.createSlideRoute(
                  //       DiscoverDetailsPage(
                  //         title: tag,
                  //         categoryType: CategoryType.category,
                  //         fullPath: "/opds/category/${tagModel.id}",
                  //       ),
                  //     ),
                  //   );
                  // },
                  child: Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildRating(double rating) {
    final int filledStars = (rating / 2).floor();
    final bool hasHalfStar = ((rating / 2) - filledStars) >= 0.5;
    const int maxStars = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxStars; i++)
          Icon(
            i < filledStars
                ? Icons.star
                : (i == filledStars && hasHalfStar)
                ? Icons.star_half
                : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
      ],
    );
  }
}
