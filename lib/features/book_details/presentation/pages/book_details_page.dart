import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docman/docman.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
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
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';

class BookDetailsPage extends StatelessWidget {
  final BookViewModel bookViewModel;
  final String bookUuid;

  const BookDetailsPage({
    super.key,
    required this.bookViewModel,
    required this.bookUuid,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create:
          (context) =>
              getIt<BookDetailsBloc>()
                ..add(LoadBookDetails(bookViewModel, bookUuid)),
      child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
        listenWhen:
            (previous, current) =>
                previous.readStatusState != current.readStatusState ||
                previous.archiveStatusState != current.archiveStatusState ||
                previous.openInReaderState != current.openInReaderState ||
                previous.metadataUpdateState != current.metadataUpdateState ||
                previous.bookDetails != current.bookDetails,
        listener: (context, state) {
          if (state.readStatusState == ReadStatusState.success) {
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
        },
        buildWhen:
            (previous, current) =>
                previous.status != current.status ||
                previous.bookDetails != current.bookDetails ||
                previous.isBookRead != current.isBookRead ||
                previous.isBookArchived != current.isBookArchived ||
                previous.metadataUpdateState != current.metadataUpdateState ||
                (previous.metadataUpdateState == MetadataUpdateState.success &&
                    current.metadataUpdateState == MetadataUpdateState.success),
        builder: (context, state) {
          final isLoading = state.status == BookDetailsStatus.loading;
          final hasError = state.status == BookDetailsStatus.error;

          if (hasError) {
            return Scaffold(
              appBar: AppBar(title: Text(localizations.error)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${localizations.errorLoadingData}: ${state.errorMessage}',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BookDetailsBloc>().add(
                          ReloadBookDetails(bookViewModel, bookUuid),
                        );
                      },
                      child: Text(localizations.tryAgain),
                    ),
                  ],
                ),
              ),
            );
          }

          final book = state.bookDetails ?? _createDummyBook(localizations);

          return Scaffold(
            appBar: AppBar(
              title:
                  isLoading
                      ? Skeletonizer(
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<BookDetailsBloc>().add(
                  ReloadBookDetails(bookViewModel, bookUuid),
                );
              },

              child: Skeletonizer(
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
    );
  }

  BookDetailsModel _createDummyBook(AppLocalizations localizations) {
    return BookDetailsModel(
      id: 0,
      uuid: 'dummy-uuid',
      title: localizations.loading,
      authors: 'Jane  & John Doe',
    );
  }

  Widget _buildBookDetails(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsState state,
    BookDetailsModel book,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              _buildCoverImage(context, book.id, localizations),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
                height: 100,
                width: double.infinity,
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withValues(alpha: .5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.by(book.authors),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .9),
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: .5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          _buildCard(
            context,
            Icons.menu_book_rounded,
            localizations.bookActions,
            _buildBookActions(context, localizations, state, book, isLoading),
          ),

          if (book.rating > 0)
            _buildCard(
              context,
              Icons.star_rate_rounded,
              localizations.rating,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildRating(book.rating),
              ),
            ),

          if (book.series.isNotEmpty)
            _buildCard(
              context,
              Icons.bookmark_rounded,
              localizations.series,
              InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createSlideRoute(
                      DiscoverDetailsPage(
                        title: book.series,
                        categoryType: CategoryType.series,
                        fullPath: "/opds/series/${book.seriesIndex}",
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 4.0,
                  ),
                  child: Text(
                    '${book.series} (${localizations.book} ${book.seriesIndex.toInt()})',
                  ),
                ),
              ),
            ),

          _buildInfoCard(
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

          _buildInfoCard(
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

          if (book.tags.isNotEmpty)
            _buildCard(
              context,
              Icons.local_offer_rounded,
              localizations.tags,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildTags(context, book.tags, book.tagModels),
              ),
            ),
          if (book.comments.isNotEmpty)
            _buildCard(
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
            ),

          const SizedBox(height: 16),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.readStatusState == ReadStatusState.loading
                      ? SizedBox(
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

          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.archiveStatusState == ArchiveStatusState.loading
                      ? SizedBox(
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

          EditBookMetadataWidget(
            book: book,
            isLoading: isLoading,
            bookViewModel: bookViewModel,
          ),
          AddToShelfWidget(book: book, isLoading: isLoading),

          DownloadToDeviceWidget(book: book, isLoading: isLoading),

          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  state.openInReaderState == OpenInReaderState.loading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Icon(Icons.open_in_new_rounded),
            ),
            onPressed:
                isLoading
                    ? null
                    : () async {
                      final settingsState = context.read<SettingsBloc>().state;
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

          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(Icons.open_in_browser_rounded),
            ),
            onPressed:
                () => context.read<BookDetailsBloc>().add(OpenBookInBrowser()),
            tooltip: localizations.openBookInBrowser,
          ),
        ],
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

  Widget _buildCoverImage(
    BuildContext context,
    int bookId,
    AppLocalizations localizations,
  ) {
    ApiService apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final username = apiService.getUsername();
    final password = apiService.getPassword();

    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: coverUrl,
        httpHeaders: {'Authorization': authHeader},
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
              child: Skeletonizer(
                enabled: true,
                effect: ShimmerEffect(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .2),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .4),
                ),
                child: SizedBox(),
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.noCoverAvailable,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        memCacheWidth: 600,
        memCacheHeight: 900,
      ),
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
                  onTap: () {
                    TagModel? tagModel = tagModels.firstWhere(
                      (tm) => tm.name == tag,
                      orElse: () => TagModel(id: 0, name: tag),
                    );
                    Navigator.of(context).push(
                      AppTransitions.createSlideRoute(
                        DiscoverDetailsPage(
                          title: tag,
                          categoryType: CategoryType.category,
                          fullPath: "/opds/category/${tagModel.id}",
                        ),
                      ),
                    );
                  },
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
    final int filledStars = rating.floor();
    final bool hasHalfStar = (rating - filledStars) >= 0.5;
    final int maxStars = 10;

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
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)} / $maxStars',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
