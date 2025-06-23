import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/book_card_skeleton_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/category_list_item_skeleton_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/category_list_item_widget.dart';
import 'package:calibre_web_companion/main.dart';

class DiscoverDetailsPage extends StatelessWidget {
  final DiscoverType? discoverType;
  final CategoryType? categoryType;
  final String? subPath;
  final String? fullPath;
  final String title;

  const DiscoverDetailsPage({
    super.key,
    this.discoverType,
    this.categoryType,
    this.subPath,
    this.fullPath,
    required this.title,
  }) : assert(
         discoverType != null || categoryType != null || fullPath != null,
         'Either discoverType, categoryType, or fullPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) {
        final bloc = getIt<DiscoverDetailsBloc>();

        // Load initial data based on provided parameters
        if (fullPath != null) {
          bloc.add(LoadBooksFromPath(fullPath!));
        } else if (discoverType != null) {
          bloc.add(LoadBooks(discoverType!, subPath: subPath));
        } else if (categoryType != null) {
          bloc.add(LoadCategories(categoryType!, subPath: subPath));
        }

        return bloc;
      },
      child: BlocConsumer<DiscoverDetailsBloc, DiscoverDetailsState>(
        listener: (context, state) {
          if (state.status == DiscoverDetailsStatus.error) {
            context.showSnackBar(
              "${localizations.errorLoadingData}: ${state.errorMessage}",
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: _buildAppBarTitle(context, title, categoryType),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<DiscoverDetailsBloc>().add(const RefreshData());
              },
              child: _buildBody(context, state, localizations),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBarTitle(
    BuildContext context,
    String title,
    CategoryType? categoryType,
  ) {
    double ratingValue = _isRatingValue(title);

    if (ratingValue == -1) {
      return Text(title);
    } else {
      return _buildStarRating(context, ratingValue);
    }
  }

  double _isRatingValue(String title) {
    final parts = title.split(' ');
    for (final part in parts) {
      if (double.tryParse(part) != null) {
        return double.parse(part);
      }
    }
    return -1;
  }

  Widget _buildStarRating(BuildContext context, double ratingValue) {
    final int fullStars = ratingValue.floor();
    final double remainder = ratingValue - fullStars;

    final List<Widget> stars = [];

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 24));
    }

    if (remainder >= 0.25 && remainder < 0.75) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 24));
    } else if (remainder >= 0.75) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 24));
    }

    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 24));
    }

    final formattedRating = ratingValue.toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text('($formattedRating)'),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    DiscoverDetailsState state,
    AppLocalizations localizations,
  ) {
    if (state.status == DiscoverDetailsStatus.loading) {
      return state.isShowingCategories
          ? _buildCategoryListSkeletons()
          : _buildBookGridSkeletons();
    }

    if (state.status == DiscoverDetailsStatus.error) {
      return _buildErrorWidget(context, state, localizations);
    }

    if (state.isShowingBooks &&
        state.bookFeed != null &&
        state.bookFeed!.books.isNotEmpty) {
      return _buildBookGrid(context, state.bookFeed!);
    }

    if (state.isShowingCategories &&
        state.categoryFeed != null &&
        state.categoryFeed!.categories.isNotEmpty) {
      return _buildCategoryList(context, state.categoryFeed!);
    }

    return _buildEmptyState(context, localizations);
  }

  Widget _buildBookGrid(BuildContext context, DiscoverFeedModel feed) {
    return BlocBuilder<DiscoverDetailsBloc, DiscoverDetailsState>(
      builder: (context, state) {
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: feed.books.length,
          itemBuilder: (context, index) {
            final book = feed.books[index];
            return BookCard(
              book: book,
              isLoading: state.loadingBookId == book.id,
              onTap:
                  () => context.read<DiscoverDetailsBloc>().add(
                    LoadDiscoverBookDetails(book.id, context),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoryFeed feed) {
    return ListView.builder(
      itemCount: feed.categories.length,
      itemBuilder: (context, index) {
        final category = feed.categories[index];
        return CategoryListItem(
          category: category,
          type: categoryType ?? CategoryType.category,
          onTap: () => _navigateToCategoryOrBooks(context, category),
        );
      },
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
      itemBuilder: (context, index) => const BookCardSkeleton(),
    );
  }

  Widget _buildCategoryListSkeletons() {
    return ListView.builder(
      itemCount: 15,
      itemBuilder: (context, index) => const CategoryListItemSkeleton(),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    DiscoverDetailsState state,
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
          Text(state.errorMessage ?? localizations.unknownError),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => context.read<DiscoverDetailsBloc>().add(
                  const RefreshData(),
                ),
            child: Text(localizations.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noDataFound,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _navigateToCategoryOrBooks(
    BuildContext context,
    CategoryModel category,
  ) {
    final String url = category.id;
    if (url.isEmpty) return;

    final pathParts = url.split('/').where((p) => p.isNotEmpty).toList();

    if (url.contains('/letter/')) {
      _navigateToLetterCategory(context, category, pathParts);
    } else if (_isNumericEndpoint(pathParts)) {
      _navigateToBookList(context, category);
    } else if (url.startsWith('/opds/')) {
      _navigateToGenericCategory(context, category, pathParts);
    } else {
      _navigateToPage(
        context,
        DiscoverDetailsPage(title: category.title, fullPath: category.id),
      );
    }
  }

  bool _isNumericEndpoint(List<String> pathParts) {
    if (pathParts.isEmpty) return false;
    return int.tryParse(pathParts.last) != null;
  }

  /// Navigation for letter categories
  void _navigateToLetterCategory(
    BuildContext context,
    CategoryModel category,
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
    final subPathIndex = category.id.indexOf(pathPrefix) + pathPrefix.length;
    final subPath = category.id.substring(subPathIndex);

    _navigateToPage(
      context,
      DiscoverDetailsPage(
        title: category.title,
        categoryType: categoryType,
        subPath: subPath,
      ),
    );
  }

  /// Navigation for numeric endpoints (direct book lists)
  void _navigateToBookList(BuildContext context, CategoryModel category) {
    _navigateToPage(
      context,
      DiscoverDetailsPage(title: category.title, fullPath: category.id),
    );
  }

  /// Navigation for generic categories
  void _navigateToGenericCategory(
    BuildContext context,
    CategoryModel category,
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
    };

    final discoverTypeMap = {
      'hot': DiscoverType.hot,
      'new': DiscoverType.newlyAdded,
      'rated': DiscoverType.rated,
      'discover': DiscoverType.discover,
      'readbooks': DiscoverType.readbooks,
      'unreadbooks': DiscoverType.unreadbooks,
    };

    final categoryType = categoryTypeMap[pathParts[1]];
    final discoverType = discoverTypeMap[pathParts[1]];

    if (categoryType != null) {
      // If a CategoryType is recognized, use this
      final subPath =
          pathParts.length > 2
              ? category.id.split('/${pathParts[1]}/').last
              : null;

      _navigateToPage(
        context,
        DiscoverDetailsPage(
          title: category.title,
          categoryType: categoryType,
          subPath: subPath,
        ),
      );
    } else if (discoverType != null) {
      // If a DiscoverType is recognized, use this
      _navigateToPage(
        context,
        DiscoverDetailsPage(title: category.title, discoverType: discoverType),
      );
    } else {
      // If no type is recognized, navigate to the generic category
      _navigateToPage(
        context,
        DiscoverDetailsPage(title: category.title, fullPath: category.id),
      );
    }
  }

  /// Navigate to a page
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, AppTransitions.createSlideRoute(page));
  }
}
