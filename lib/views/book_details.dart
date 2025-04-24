import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/app_transition.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/views/book_list.dart';
import 'package:calibre_web_companion/views/widgets/add_to_shelf.dart';
import 'package:calibre_web_companion/views/widgets/download_to_device.dart';
import 'package:calibre_web_companion/views/widgets/edit_book_metadata.dart';
import 'package:calibre_web_companion/views/widgets/send_to_ereader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookDetails extends StatefulWidget {
  final String bookUuid;
  const BookDetails({super.key, required this.bookUuid});

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  late Future _loadingFuture;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadBookData();
  }

  Future _loadBookData() async {
    return Provider.of<BookDetailsViewModel>(
      context,
      listen: false,
    ).fetchBook(bookUuid: widget.bookUuid);
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return FutureBuilder(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.error)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${localizations.errorLoadingData}: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadingFuture = _loadBookData();
                      });
                    },
                    child: Text(localizations.tryAgain),
                  ),
                ],
              ),
            ),
          );
        }

        final isInitialLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return Consumer<BookDetailsViewModel>(
          builder: (context, viewModel, _) {
            final isLoading = isInitialLoading || viewModel.isReloading;

            if (viewModel.currentBook == null &&
                !snapshot.hasError &&
                !isLoading) {
              return Scaffold(
                appBar: AppBar(title: Text(localizations.book)),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final book =
                viewModel.currentBook ?? _createDummyBook(localizations);

            return Scaffold(
              appBar: AppBar(
                title:
                    isLoading
                        ? Skeletonizer(
                          enabled: true,
                          effect: ShimmerEffect(
                            baseColor: Theme.of(
                              context,
                              // ignore: deprecated_member_use
                            ).colorScheme.primary.withOpacity(0.2),
                            highlightColor: Theme.of(
                              context,
                              // ignore: deprecated_member_use
                            ).colorScheme.primary.withOpacity(0.4),
                          ),
                          child: Container(
                            height: 20,
                            width: 300,
                            color: const Color.fromARGB(255, 0, 0, 0),
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

              body: Skeletonizer(
                enabled: isLoading,
                effect: ShimmerEffect(
                  baseColor: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.primary.withOpacity(0.2),
                  highlightColor: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.primary.withOpacity(0.4),
                ),
                child: _buildBookDetails(
                  context,
                  localizations,
                  viewModel,
                  book,
                  isLoading,
                ),
              ),
              floatingActionButton:
                  isLoading ? null : SendToEreader(book: book),
            );
          },
        );
      },
    );
  }

  BookItem _createDummyBook(AppLocalizations localizations) {
    return BookItem(
      id: 'dummy-id',
      uuid: 'dummy-uuid',
      title: localizations.loading,
      author: 'Jane Smith & John Doe',
      summary:
          'This is a placeholder description for the book. It contains multiple sentences to show what the actual description might look like when the real data is loaded. This text is intentionally long to demonstrate how the skeleton will appear for longer content blocks.',
      updated: DateTime.now(),
      published: DateTime.now(),
      publisher: 'Sample Publisher',
      language: 'eng',
      rating: 7.5,
      fileSize: 2500000,
      series: 'Great Sample Series',
      seriesIndex: 2.0,
      formats: ['EPUB', 'MOBI', 'PDF'],
      categories: ['Fiction', 'Science Fiction', 'Adventure', 'Fantasy'],
    );
  }

  /// Builds the book details view
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to display
  Widget _buildBookDetails(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsViewModel viewModel,
    BookItem book,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image with gradient overlay (keep as is)
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              // Cover image
              _buildCoverImage(context, book.id, localizations),

              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // ignore: deprecated_member_use
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
                height: 100,
                width: double.infinity,
              ),

              // Title and Author overlay
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
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.by(book.author),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Book Actions
          _buildCard(
            context,
            Icons.menu_book_rounded,
            localizations.bookActions,
            _buildBookActions(
              context,
              viewModel,
              localizations,
              book,
              isLoading,
            ),
          ),

          // Rating section
          if (book.rating != null && book.rating! > 0)
            _buildCard(
              context,
              Icons.star_rate_rounded,
              localizations.rating,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildRating(book.rating!),
              ),
            ),

          // Series info if available
          if (book.series != null)
            _buildCard(
              context,
              Icons.bookmark_rounded,
              localizations.series,
              InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createSlideRoute(
                      BookList(
                        title: book.series!,
                        categoryType: CategoryType.series,
                        fullPath: "/opds/series/${book.seriesId}",
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
                    book.seriesIndex != null
                        ? '${book.series} (${localizations.book} ${book.seriesIndex?.toInt()})'
                        : book.series!,
                  ),
                ),
              ),
            ),

          // Publication Info section
          _buildInfoCard(
            context,
            Icons.info_outline_rounded,
            localizations.publicationInfo,
            [
              if (book.published != null)
                _buildInfoRow(
                  context,
                  localizations.published,
                  intl.DateFormat.yMMMMd(
                    localizations.localeName,
                  ).format(book.published!),
                  Icons.calendar_today_rounded,
                ),
              if (book.updated != null && book.published != null)
                _buildInfoRow(
                  context,
                  localizations.updated,
                  intl.DateFormat.yMMMMd(
                    localizations.localeName,
                  ).format(book.published!),
                  Icons.update_rounded,
                ),
              if (book.publisher != null && book.publisher!.isNotEmpty)
                _buildInfoRow(
                  context,
                  localizations.publisher,
                  book.publisher!,
                  Icons.business_rounded,
                ),
              if (book.language!.isNotEmpty)
                _buildInfoRow(
                  context,
                  localizations.language,
                  _formatLanguage(book.language!, localizations),
                  Icons.language_rounded,
                ),
            ],
          ),

          // File Info section
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
              if (book.fileSize != null)
                _buildInfoRow(
                  context,
                  localizations.size,
                  _formatFileSize(book.fileSize!),
                  Icons.data_usage_rounded,
                ),
              _buildInfoRow(context, 'ID', book.uuid, Icons.tag_rounded),
            ],
          ),

          // Tags section
          if (book.categories.isNotEmpty)
            _buildCard(
              context,
              Icons.local_offer_rounded,
              localizations.categories,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildTags(context, book.categories),
              ),
            ),

          // Description section
          if (book.summary!.isNotEmpty)
            _buildCard(
              context,
              Icons.article_rounded,
              localizations.description,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  book.summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Helper method to create a card with an icon and title
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [icon]: The icon to display
  /// - [title]: The title of the card
  /// - [child]: The child widget to display in the card
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
          // Card header with icon and title
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

          // Divider
          const Divider(height: 4),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Builds the book actions row
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [localizations]: The localized strings
  /// - [book]: The book item to display
  /// - [isLoading]: Whether the book is currently loading
  Widget _buildBookActions(
    BuildContext context,
    BookDetailsViewModel viewModel,
    AppLocalizations localizations,
    BookItem book,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Read/Unread toggle
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  Provider.of<BookDetailsViewModel>(context).isReadToggleLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Provider.of<BookDetailsViewModel>(context).isBookRead
                      ? Icon(Icons.visibility)
                      : Icon(Icons.visibility_off),
            ),
            onPressed:
                isLoading
                    ? null
                    : () => Provider.of<BookDetailsViewModel>(
                          context,
                          listen: false,
                        )
                        .toggleReadStatus(book.id)
                        .then(
                          // ignore: use_build_context_synchronously
                          (res) => context.showSnackBar(
                            res
                                ? (Provider.of<BookDetailsViewModel>(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      listen: false,
                                    ).isBookRead
                                    ? localizations.markedAsReadSuccessfully
                                    : localizations.markedAsUnreadSuccessfully)
                                : (Provider.of<BookDetailsViewModel>(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      listen: false,
                                    ).isBookRead
                                    ? localizations.markedAsReadFailed
                                    : localizations.markedAsUnreadFailed),
                            isError: !res,
                          ),
                        ),
            tooltip: localizations.markAsReadUnread,
          ),
          // Archive/Unarchive toggle
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child:
                  Provider.of<BookDetailsViewModel>(context).isArchivedLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                      : Icon(
                        Provider.of<BookDetailsViewModel>(context).isArchived
                            ? Icons.archive
                            : Icons.unarchive,
                      ),
            ),
            onPressed:
                isLoading
                    ? null
                    : () async {
                      bool success = await Provider.of<BookDetailsViewModel>(
                        context,
                        listen: false,
                      ).toggleArchivedStatus(book.id);

                      // ignore: use_build_context_synchronously
                      context.showSnackBar(
                        success
                            ? (Provider.of<BookDetailsViewModel>(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  listen: false,
                                ).isArchived
                                ? localizations.archivedBookSuccessfully
                                : localizations.unarchivedBookSuccessfully)
                            : (Provider.of<BookDetailsViewModel>(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  listen: false,
                                ).isArchived
                                ? localizations.archivedBookFailed
                                : localizations.unarchivedBookFailed),
                        isError: !success,
                      );
                    },
            tooltip: localizations.archiveUnarchive,
          ),
          EditBookMetadata(
            book: book,
            isLoading: isLoading,
            viewModel: viewModel,
          ),
          AddToShelf(book: book, isLoading: isLoading),
          DownloadToDevice(book: book, isLoading: isLoading),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(Icons.open_in_browser_rounded),
            ),
            onPressed: () async {
              await viewModel.openInBrowser(book);
            },
            tooltip: localizations.openBookInBrowser,
          ),
        ],
      ),
    );
  }

  /// Helper method to create an info card with multiple rows
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [icon]: The icon for the card
  /// - [title]: The title of the card
  /// - [children]: The children widgets to display
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

  /// Helper method to create info rows
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [label]: The label for the info row
  /// - [value]: The value for the info row
  /// - [icon]: The icon for the info row
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
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
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

  /// Formats a language code to a human-readable name
  ///
  /// Parameters:
  ///
  /// - [languageCode]: The language code to format
  String _formatLanguage(String languageCode, AppLocalizations localizations) {
    // Maps language codes to human-readable names
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

  /// Formats a file size in bytes to a human-readable format
  ///
  /// Parameters:
  ///
  /// - [sizeInBytes]: The file size in bytes
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Builds the cover image for the book
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [bookId]: The ID of the book to fetch the cover for
  Widget _buildCoverImage(
    BuildContext context,
    String bookId,
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
                // ignore: deprecated_member_use
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Skeletonizer(
                enabled: true,
                effect: ShimmerEffect(
                  baseColor: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.primary.withOpacity(0.2),
                  highlightColor: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.primary.withOpacity(0.4),
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

  /// Builds a list of tags
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [tags]: The list of tags to display
  Widget _buildTags(BuildContext context, List<String> tags) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(tag),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Builds a rating widget
  ///
  /// Parameters:
  ///
  /// - [rating]: The rating to display
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
