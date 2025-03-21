import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/book_recommendation_view_model.dart';
import 'package:calibre_web_companion/view_models/download_service_view_model.dart';
import 'package:calibre_web_companion/views/widgets/book_recommendation_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookRecommendationsView extends StatefulWidget {
  const BookRecommendationsView({super.key});

  @override
  BookRecommendationsViewState createState() => BookRecommendationsViewState();
}

class BookRecommendationsViewState extends State<BookRecommendationsView> {
  bool isLoading = false;
  int loadingRecommendationId = 0;

  // Dummy-Data
  final List<BookRecommendation> _dummyRecommendations = List.generate(
    6,
    (index) => BookRecommendation(
      id: index,
      title: 'Sample Book Title That is Long',
      author: ['Famous Author Name'],
      coverUrl: 'https://via.placeholder.com/400x600',
      about: ['This is a sample book description.'],
      reactions: ['sample tag 1', 'sample tag 2'],
      sourceBookId: 1,
      sourceBookTitle: 'Source Book Title',
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookRecommendationsViewModel>(
        context,
        listen: false,
      ).loadUserBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bookRecommendations),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_rounded),
            onPressed: () {
              _showInfoDialog(context, localizations);
            },
            tooltip: localizations.info,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<BookRecommendationsViewModel>(
                context,
                listen: false,
              ).loadUserBooks();
            },
            tooltip: localizations.refresh,
          ),
        ],
      ),
      body: Consumer<BookRecommendationsViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildSelectionHeader(context, viewModel, localizations),

              if (viewModel.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    viewModel.error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child:
                    viewModel.isLoadingRecommendations
                        ? _buildSkeletonRecommendations(context)
                        : _buildRecommendationsList(
                          context,
                          viewModel,
                          localizations,
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the skeleton for the recommendations
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  Widget _buildSkeletonRecommendations(BuildContext context) {
    return Skeletonizer(
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
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _dummyRecommendations.length,
        itemBuilder: (context, index) {
          return BookRecommendationCard(
            recommendation: _dummyRecommendations[index],
            isLoading: isLoading,
            loadingRecommendationId: loadingRecommendationId,
            onDownload: () {},
            onTap: () {},
          );
        },
      ),
    );
  }

  /// Shows the info dialog
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The localized strings
  _showInfoDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.bookRecommendations),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  text: localizations.bookRecommendationsInfo1,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'meetnewbook.com',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: localizations.bookRecommendationsInfo2),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              label: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  /// Builds the header with the book selection dropdown
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to get the data from
  /// - `localizations`: The localized strings
  Widget _buildSelectionHeader(
    BuildContext context,
    BookRecommendationsViewModel viewModel,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectABookFromYourLibrary,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child:
                    viewModel.isLoadingBooks
                        ? _buildSkeletonDropdown()
                        : _buildBookDropdown(context, viewModel, localizations),
              ),
              if (viewModel.selectedBook != null)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (viewModel.selectedBook != null) {
                      viewModel.loadRecommendationsForBook(
                        viewModel.selectedBook!,
                      );
                    }
                  },
                  tooltip: localizations.searchRecommendations,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonDropdown() {
    return Skeletonizer(
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
      child: DropdownButtonFormField<String>(
        value: "Sample Book (Author)",
        isExpanded: true,
        decoration: InputDecoration(
          hintText: "Select a book",
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: [
          DropdownMenuItem<String>(
            value: "Sample Book (Author)",
            child: Text("Sample Book (Author)"),
          ),
        ],
        onChanged: null,
      ),
    );
  }

  /// Builds the dropdown to select a book
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to get the data from
  /// - `localizations`: The localized strings
  Widget _buildBookDropdown(
    BuildContext context,
    BookRecommendationsViewModel viewModel,
    AppLocalizations localizations,
  ) {
    if (viewModel.userBooks.isEmpty) {
      return Text(localizations.noBooksFound);
    }

    return DropdownButtonFormField<BookItem>(
      value: viewModel.selectedBook,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: localizations.selectBook,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items:
          viewModel.userBooks.map((book) {
            return DropdownMenuItem<BookItem>(
              value: book,
              child: Text(
                '${book.title} (${book.author})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged: (book) {
        viewModel.selectedBook = book;
      },
    );
  }

  /// Builds the list of recommendations
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to get the data from
  /// - `localizations`: The localized strings
  Widget _buildRecommendationsList(
    BuildContext context,
    BookRecommendationsViewModel viewModel,
    AppLocalizations localizations,
  ) {
    if (viewModel.selectedBook == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.selectABookToGetRecommendations,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.recommendations.isEmpty && viewModel.error.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noRecommendationsFoundForThisBook,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.matchingBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noMatchingBooksFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.recommendations.length,
      itemBuilder: (context, index) {
        final downloadViewModel = context.watch<DownloadServiceViewModel>();

        final recommendation = viewModel.recommendations[index];
        return BookRecommendationCard(
          recommendation: recommendation,
          isLoading: isLoading,
          loadingRecommendationId: loadingRecommendationId,
          onTap: () {
            _showBookDetails(context, recommendation, localizations);
          },
          onDownload: () async {
            isLoading = true;
            loadingRecommendationId = recommendation.id;
            await downloadViewModel.searchBooks(
              '${recommendation.title} ${recommendation.author.join(' ')}',
            );

            if (downloadViewModel.searchResults.isNotEmpty) {
              downloadViewModel.downloadBook(
                downloadViewModel.searchResults.first.id,
              );

              // ignore: use_build_context_synchronously
              context.showSnackBar(
                localizations.addedBookToTheDownloadQueue,
                isError: false,
              );
            } else {
              // ignore: use_build_context_synchronously
              context.showSnackBar(
                localizations.bookCouldNotBeFound,
                isError: true,
              );
            }

            if (downloadViewModel.error != null) {
              // ignore: use_build_context_synchronously
              context.showSnackBar(downloadViewModel.error!, isError: true);
            }

            downloadViewModel.clearSearchResults();
            isLoading = false;
          },
        );
      },
    );
  }

  /// Shows details for a book recommendation
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `recommendation`: The book recommendation to show details for
  /// - `localizations`: The localized strings
  void _showBookDetails(
    BuildContext context,
    BookRecommendation recommendation,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: recommendation.coverUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.error_outline, size: 48),
                        ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.author.join(', '),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const Divider(height: 24),

                      _buildInfoSection(
                        context,
                        localizations.recommendedBasedOn,
                        _removeHTMLFromTitle(recommendation.sourceBookTitle),
                        Icons.book,
                      ),

                      const SizedBox(height: 16),

                      if (recommendation.about.isNotEmpty)
                        _buildInfoSection(
                          context,
                          localizations.about,
                          recommendation.about.join('\n\n'),
                          Icons.description,
                        ),

                      const SizedBox(height: 16),

                      if (recommendation.reactions.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tag,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  localizations.tags,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      recommendation.reactions.map((tag) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: Chip(
                                            label: Text(tag),
                                            backgroundColor:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            labelStyle: TextStyle(
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(localizations.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a section with an icon, title and content
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `title`: The title of the section
  /// - `content`: The content of the section
  /// - `icon`: The icon to display
  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  /// Removes HTML tags from a title
  ///
  /// Parameters:
  ///
  /// - `sourceTitle`: The title with HTML tags
  String _removeHTMLFromTitle(String sourceTitle) {
    final noHtml = sourceTitle.replaceAll(RegExp(r'<[^>]*>'), '');

    return noHtml;
  }
}
