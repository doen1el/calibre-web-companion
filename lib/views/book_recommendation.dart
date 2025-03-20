import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/view_models/book_recommendation_view_model.dart';
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<BookRecommendationsViewModel>(
                context,
                listen: false,
              ).loadUserBooks();
            },
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

  // Skelett-Ansicht mit Dummy-Daten
  Widget _buildSkeletonRecommendations(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Angepasst um Overflow zu vermeiden
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _dummyRecommendations.length,
        itemBuilder: (context, index) {
          return BookRecommendationCard(
            recommendation: _dummyRecommendations[index],
            onDownload: () {},
          );
        },
      ),
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
      return Center(child: Text(localizations.selectABookToGetRecommendations));
    }

    if (viewModel.recommendations.isEmpty && viewModel.error.isEmpty) {
      return Center(
        child: Text(localizations.noRecommendationsFoundForThisBook),
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
        final recommendation = viewModel.recommendations[index];
        return BookRecommendationCard(
          recommendation: recommendation,
          onDownload: () {},
        );
      },
    );
  }
}
