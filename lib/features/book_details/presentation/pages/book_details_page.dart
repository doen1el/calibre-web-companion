import 'dart:async';

import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logger/logger.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/app_skeletonizer.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
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
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';

class BookDetailsPage extends StatefulWidget {
  final BookViewModel bookViewModel;
  final String bookUuid;

  const BookDetailsPage({
    super.key,
    required this.bookViewModel,
    required this.bookUuid,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool _didUpdateMetadata = false;
  StreamSubscription<dynamic>? _locatorSubscription;
  late final WebDavSyncService _webDavService;

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
        formats
            .where((format) => _isInternalReaderSupportedFormat(format))
            .toList();

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
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(localizations.downlaodFomat),
                  leading: const Icon(Icons.menu_book_rounded),
                ),
                const Divider(),
                ...formats.map((format) {
                  final isSupported = _isInternalReaderSupportedFormat(format);
                  IconData icon;

                  switch (format) {
                    case 'epub':
                      icon = Icons.menu_book;
                      break;
                    case 'pdf':
                      icon = Icons.picture_as_pdf;
                      break;
                    case 'kepub':
                      icon = Icons.book;
                      break;
                    default:
                      icon = Icons.file_present;
                  }

                  return ListTile(
                    leading: Icon(
                      icon,
                      color:
                          isSupported
                              ? null
                              : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text(format.toUpperCase()),
                    subtitle:
                        isSupported
                            ? null
                            : Text(
                              localizations.internalReaderSupportsOnlyEpubShort,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                    onTap: () {
                      Navigator.pop(sheetContext, isSupported ? format : null);
                    },
                  );
                }),
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
  }

  Future<void> _initWebDav() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('webdav_enabled') ?? false;
    if (enabled) {
      _webDavService.init(
        prefs.getString('webdav_url') ?? '',
        prefs.getString('webdav_username') ?? '',
        prefs.getString('webdav_password') ?? '',
      );
    }
  }

  @override
  void dispose() {
    _locatorSubscription?.cancel();
    VocsyEpub.closeReader();
    super.dispose();
  }

  Future<void> _openInternalReader(
    BuildContext context,
    String filePath,
    BookDetailsModel bookDetailsModel,
  ) async {
    final lastLocation = context.read<BookDetailsBloc>().state.startLocation;
    final settingsState = context.read<SettingsBloc>().state;

    if (!filePath.toLowerCase().endsWith('.epub')) {
      final localization = AppLocalizations.of(context)!;
      context.showSnackBar(
        localization.errorOpeningBookInInternalReaderPdf,
        isError: true,
        duration: const Duration(seconds: 10),
      );
      return;
    }

    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      identifier: "book_${bookDetailsModel.uuid}",
      scrollDirection:
          settingsState.epubScrollDirection == 'horizontal'
              ? EpubScrollDirection.HORIZONTAL
              : EpubScrollDirection.VERTICAL,
      allowSharing: true,
      enableTts: true,
      nightMode: Theme.of(context).brightness == Brightness.dark,
    );

    await _locatorSubscription?.cancel();

    _locatorSubscription = VocsyEpub.locatorStream.listen((locator) {
      // ignore: use_build_context_synchronously
      context.read<BookDetailsBloc>().add(
        SyncReadingProgress(bookDetailsModel.uuid, locator),
      );
    });

    VocsyEpub.open(filePath, lastLocation: lastLocation);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
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
                state.downloadFilePath != null) {
              context.read<BookDetailsBloc>().add(const ClearSnackBarStates());

              _openInternalReader(
                context,
                state.downloadFilePath!,
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
                              ? "${book.title.substring(0, 30)}..."
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
                              '${book.series} (${localizations.book} ${book.seriesIndex.toInt()})',
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
              if (book.pubdate != "")
                _buildInfoRow(
                  context,
                  localizations.updated,
                  intl.DateFormat.yMMMMd(
                    localizations.localeName,
                  ).format(DateTime.parse(book.pubdate)),
                  Icons.update_rounded,
                ),
              if (book.publishers != "")
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
    final isOpds = serverType == 'opds' || serverType == 'booklore';

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

                      DocumentFile? selectedDirectory;

                      if (settingsState.defaultDownloadPath.isEmpty) {
                        selectedDirectory = await DocMan.pick.directory();
                        if (selectedDirectory == null) {
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

                      // ignore: use_build_context_synchronously
                      context.read<BookDetailsBloc>().add(
                        OpenBookInInternalReader(
                          selectedDirectory: selectedDirectory,
                          schema: settingsState.downloadSchema,
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

                      // ignore: use_build_context_synchronously
                      context.read<BookDetailsBloc>().add(
                        OpenBookInReader(
                          selectedDirectory: selectedDirectory,
                          schema: settingsState.downloadSchema,
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
                () => context.read<BookDetailsBloc>().add(OpenBookInBrowser()),
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
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: Text(
                                  localizations.delete,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onError,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text(localizations.cancel),
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

    final unsupportedOnOpds = <String>{
      BookDetailsAction.toggleReadStatus.key,
      BookDetailsAction.toggleArchiveStatus.key,
      BookDetailsAction.editMetadata.key,
      BookDetailsAction.addToShelf.key,
      BookDetailsAction.openInBrowser.key,
      BookDetailsAction.deleteBook.key,
    };

    final visibleOrder =
        settingsState.bookActionsOrder.where((actionKey) {
          final isEnabled = enabledActionKeys.contains(actionKey);
          final exists = actionBuilders.containsKey(actionKey);
          final isSupported = !isOpds || !unsupportedOnOpds.contains(actionKey);
          return isEnabled && exists && isSupported;
        }).toList();

    if (visibleOrder.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            visibleOrder
                .map((actionKey) => actionBuilders[actionKey]!())
                .toList(),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget child,
  ) {
    BorderRadius borderRadius = BorderRadius.circular(12.0);

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
    var languageMap = {
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
    final int maxStars = 5;

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
