import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/app_transition.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/views/widgets/book_card.dart';
import 'package:calibre_web_companion/views/widgets/book_card_skeleton.dart';
import 'package:calibre_web_companion/views/widgets/category_list_item.dart';
import 'package:calibre_web_companion/views/widgets/category_list_item_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookList extends StatefulWidget {
  final BookListType? bookListType;
  final CategoryType? categoryType;
  final String? subPath;
  final String? fullPath;
  final String title;

  const BookList({
    super.key,
    this.bookListType,
    this.categoryType,
    this.subPath,
    this.fullPath,
    required this.title,
  }) : assert(
         bookListType != null || categoryType != null || fullPath != null,
         'Either bookListType, categoryType, or fullPath must be provided',
       );

  @override
  BookListState createState() => BookListState();
}

class BookListState extends State<BookList> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register this route for routeObserver
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // Unregister this route for routeObserver
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadData();
  }

  @override
  void didUpdateWidget(BookList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookListType != widget.bookListType ||
        oldWidget.categoryType != widget.categoryType ||
        oldWidget.subPath != widget.subPath) {
      _loadData();
    }
  }

  void _loadData() {
    final viewModel = context.read<BookListViewModel>();

    // If a full path is provided, load books from that path
    if (widget.fullPath != null) {
      viewModel.loadBooksFromPath(widget.fullPath!);
    }
    // Otherwise, load books based on the type
    else if (widget.bookListType != null) {
      viewModel.loadBooks(widget.bookListType!, subPath: widget.subPath);
    } else if (widget.categoryType != null) {
      viewModel.loadCategories(widget.categoryType!, subPath: widget.subPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Consumer<BookListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            // If we're loading categories, show category skeletons
            if (widget.categoryType != null && widget.bookListType == null) {
              return _buildCategoryListSkeletons();
            }

            // Otherwise show skeleton book cards
            return _buildBookGridSkeletons();
          }

          if (viewModel.hasError) {
            _buildErrorWidget(viewModel, localizations);
          }

          // Display books as grid
          if (viewModel.bookFeed != null) {
            return _buildBookGrid(viewModel.bookFeed!);
          }

          // Display categories as list
          if (viewModel.categoryFeed != null) {
            return _buildCategoryList(viewModel.categoryFeed!);
          }

          return Center(child: Text(localizations.noDataFound));
        },
      ),
    );
  }

  /// Build a grid of skeleton book cards for loading state
  Widget _buildBookGridSkeletons() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: 10, // Show a reasonable number of skeletons
      itemBuilder: (context, index) {
        return const BookCardSkeleton();
      },
    );
  }

  /// Build a list of skeleton category items for loading state
  Widget _buildCategoryListSkeletons() {
    return ListView.builder(
      itemCount: 15, // Show a reasonable number of skeletons
      itemBuilder: (context, index) {
        return const CategoryListItemSkeleton();
      },
    );
  }

  /// Build an error widget
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to get the error message from
  Widget _buildErrorWidget(
    BookListViewModel viewModel,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.errorLoadingData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(viewModel.errorMessage ?? localizations.unknownError),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(localizations.tryAgain),
          ),
        ],
      ),
    );
  }

  /// Build a grid of books
  ///
  /// Parameters:
  ///
  /// - `feed`: The feed to build the grid from
  Widget _buildBookGrid(OpdsFeed<BookItem> feed) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: feed.items.length,
      itemBuilder: (context, index) {
        final book = feed.items[index];
        return BookCard(book: book);
      },
    );
  }

  /// Build a list of categories
  ///
  /// Parameters:
  ///
  /// - `feed`: The feed to build the list from
  Widget _buildCategoryList(OpdsFeed<CategoryItem> feed) {
    return ListView.builder(
      itemCount: feed.items.length,
      itemBuilder: (context, index) {
        final category = feed.items[index];

        return CategoryListItem(
          category: category,
          type: widget.categoryType!,
          onTap: () {
            _navigateToCategoryOrBooks(context, category);
          },
        );
      },
    );
  }

  /// Navigate to the category or books based on the category item
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `category`: The category item to navigate to
  void _navigateToCategoryOrBooks(BuildContext context, CategoryItem category) {
    final String url = category.navigationUrl;
    if (url.isEmpty) return;

    // Split the URL into parts
    final pathParts = url.split('/').where((p) => p.isNotEmpty).toList();

    // Check the URL for specific patterns
    if (url.contains('/letter/')) {
      _navigateToLetterCategory(context, category, pathParts);
    } else if (_isNumericEndpoint(pathParts)) {
      _navigateToBookList(context, category);
    } else if (url.startsWith('/opds/')) {
      _navigateToGenericCategory(context, category, pathParts);
    }
  }

  /// Check if the URL endpoint is numeric
  ///
  /// Parameters:
  ///
  /// - `pathParts`: The parts of the URL path
  bool _isNumericEndpoint(List<String> pathParts) {
    if (pathParts.isEmpty) return false;
    return int.tryParse(pathParts.last) != null;
  }

  /// Navigation for letter categories
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `category`: The category item to navigate to
  /// - `pathParts`: The parts of the URL path
  void _navigateToLetterCategory(
    BuildContext context,
    CategoryItem category,
    List<String> pathParts,
  ) {
    if (pathParts.length < 2) return;

    final categoryTypeMap = {
      'author': CategoryType.author,
      'series': CategoryType.series,
      'category': CategoryType.category,
      'publisher': CategoryType.publisher,
      'language': CategoryType.language,
      'formats': CategoryType.formats,
      'ratings': CategoryType.ratings,
    };

    final categoryType = categoryTypeMap[pathParts[1]];
    if (categoryType == null) return;

    // Extract the subpath
    final pathPrefix = '/${pathParts[1]}/';
    final subPathIndex =
        category.navigationUrl.indexOf(pathPrefix) + pathPrefix.length;
    final subPath = category.navigationUrl.substring(subPathIndex);

    _navigateToPage(
      context,
      BookList(
        title: category.title,
        categoryType: categoryType,
        subPath: subPath,
      ),
    );
  }

  /// Navigation for numeric endpoints
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `category`: The category item to navigate to
  void _navigateToBookList(BuildContext context, CategoryItem category) {
    _navigateToPage(
      context,
      BookList(title: category.title, fullPath: category.navigationUrl),
    );
  }

  /// Navigation for generic categories
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `category`: The category item to navigate to
  /// - `pathParts`: The parts of the URL path
  void _navigateToGenericCategory(
    BuildContext context,
    CategoryItem category,
    List<String> pathParts,
  ) {
    if (pathParts.length < 2) return;

    // Map category types to their respective enum values
    final categoryTypeMap = {
      'author': CategoryType.author,
      'series': CategoryType.series,
      'category': CategoryType.category,
      'publisher': CategoryType.publisher,
      'language': CategoryType.language,
      'formats': CategoryType.formats,
      'ratings': CategoryType.ratings,
      'hot': BookListType.hot,
      'new': BookListType.newlyAdded,
      'rated': BookListType.rated,
      'discover': BookListType.discover,
    };

    final type = categoryTypeMap[pathParts[1]];

    if (type is CategoryType) {
      // If a CategoryType is recognized, use this
      final subPath =
          pathParts.length > 2
              ? category.navigationUrl.split('/${pathParts[1]}/').last
              : null;

      _navigateToPage(
        context,
        BookList(title: category.title, categoryType: type, subPath: subPath),
      );
    } else if (type is BookListType) {
      // If a BookListType is recognized, use this
      _navigateToPage(
        context,
        BookList(title: category.title, bookListType: type),
      );
    } else {
      // If no type is recognized, navigate to the generic category
      _navigateToPage(
        context,
        BookList(title: category.title, fullPath: category.navigationUrl),
      );
    }
  }

  /// Navigate to a page
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `page`: The page to navigate to
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, AppTransitions.createSlideRoute(page));
  }
}
