import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/views/widgets/book_card.dart';
import 'package:calibre_web_companion/views/widgets/book_card_skeleton.dart';
import 'package:calibre_web_companion/views/widgets/search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/view_models/books_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BooksView extends StatefulWidget {
  const BooksView({super.key});

  @override
  State<BooksView> createState() => _BookListViewState();
}

class _BookListViewState extends State<BooksView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener for infinite scrolling
  void _scrollListener() {
    final viewModel = Provider.of<BooksViewModel>(context, listen: false);
    if (!viewModel.isLoading &&
        viewModel.hasMoreBooks &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500) {
      viewModel.fetchMoreBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BooksViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    if (viewModel.hasError) {
      context.showSnackBar(viewModel.errorMessage, isError: true);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.books),
        actions: [
          _buildSortOptions(viewModel, localizations),
          _buildSearchButton(viewModel),
        ],
      ),
      body: Consumer<BooksViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.books.isEmpty && viewModel.isLoading) {
            return _buildBookGridSkeletons();
          }

          if (viewModel.books.isEmpty && viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.errorLoadingBooks,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(viewModel.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshBooks(),
                    child: Text(localizations.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (viewModel.books.isEmpty) {
            return Center(child: Text(localizations.noBooksFound));
          }

          return _buildRefreshIndicatorAndGridView(viewModel);
        },
      ),
    );
  }

  Widget _buildBookGridSkeletons() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const BookCardSkeleton();
      },
    );
  }

  /// Builds the sort options popup menu
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildSortOptions(
    BooksViewModel viewModel,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (String value) {
        final sortParts = value.split(':');
        if (sortParts.length == 2) {
          viewModel.setSorting(sortParts[0], sortParts[1]);
        }
      },
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem(
              value: 'title:asc',
              child: Text(localizations.titleAZ),
            ),
            PopupMenuItem(
              value: 'title:desc',
              child: Text(localizations.titleZA),
            ),
            PopupMenuItem(
              value: 'authors:asc',
              child: Text(localizations.authorAZ),
            ),
            PopupMenuItem(
              value: 'authors:desc',
              child: Text(localizations.authorZA),
            ),
            PopupMenuItem(
              value: 'added:desc',
              child: Text(localizations.newestFirst),
            ),
            // TODO: Fix sorting by added ascending
            // PopupMenuItem(
            //   value: 'added:asc',
            //   child: Text(localizations.oldestFirst),
            // ),
          ],
    );
  }

  /// Builds the search button
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildSearchButton(BooksViewModel viewModel) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final searchQuery = await showDialog<String>(
          context: context,
          builder: (context) => SearchDialog(),
        );

        if (searchQuery != null) {
          viewModel.setSearchQuery(searchQuery);
        }
      },
    );
  }

  /// Builds the refresh indicator and grid view
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildRefreshIndicatorAndGridView(BooksViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshBooks(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount:
            viewModel.hasMoreBooks
                ? viewModel.books.length + 1
                : viewModel.books.length,
        itemBuilder: (context, index) {
          if (index == viewModel.books.length) {
            return BookCardSkeleton();
          }
          return BookCard(book: viewModel.books[index]);
        },
      ),
    );
  }
}
