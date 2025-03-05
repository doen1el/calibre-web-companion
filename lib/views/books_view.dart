import 'package:calibre_web_companion/views/widgets/book_card.dart';
import 'package:calibre_web_companion/views/widgets/search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/view_models/books_view_model.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [_buildSortOptions(viewModel), _buildSearchButton(viewModel)],
      ),
      body: Consumer<BooksViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.books.isEmpty && viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.books.isEmpty && viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading books',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(viewModel.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshBooks(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.books.isEmpty) {
            return const Center(child: Text('No books found'));
          }

          return _buildRefreshIndicatorAndGridView(viewModel);
        },
      ),
    );
  }

  Widget _buildSortOptions(BooksViewModel viewModel) {
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
            const PopupMenuItem(value: 'title:asc', child: Text('Title (A-Z)')),
            const PopupMenuItem(
              value: 'title:desc',
              child: Text('Title (Z-A)'),
            ),
            const PopupMenuItem(
              value: 'authors:asc',
              child: Text('Author (A-Z)'),
            ),
            const PopupMenuItem(
              value: 'authors:desc',
              child: Text('Author (Z-A)'),
            ),
            const PopupMenuItem(
              value: 'pubdate:desc',
              child: Text('Newest First'),
            ),
            const PopupMenuItem(
              value: 'pubdate:asc',
              child: Text('Oldest First'),
            ),
          ],
    );
  }

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

  Widget _buildRefreshIndicatorAndGridView(BooksViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshBooks(),
      child: GridView.builder(
        controller: _scrollController, // Make sure the controller is connected
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.5,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemCount:
            viewModel.hasMoreBooks
                ? viewModel.books.length + 1
                : viewModel.books.length,
        itemBuilder: (context, index) {
          if (index == viewModel.books.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return BookCard(book: viewModel.books[index], onTap: () {});
        },
      ),
    );
  }
}
