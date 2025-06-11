import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/book_skeleton.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/category_list_item_skeleton_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/category_list_item_widget.dart';
import 'package:calibre_web_companion/main.dart';

class DiscoverDetailsPage extends StatelessWidget {
  final DiscoverType? bookListType;
  final CategoryType? categoryType;
  final String? subPath;
  final String? fullPath;
  final String title;

  const DiscoverDetailsPage({
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) {
        final bloc = getIt<DiscoverDetailsBloc>();

        // Load initial data based on provided parameters
        if (fullPath != null) {
          bloc.add(LoadBooksFromPath(fullPath!));
        } else if (bookListType != null) {
          bloc.add(LoadBooks(bookListType!, subPath: subPath));
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
          onTap: () {},
          // TODO: Implement navigation to book details page
          // () => Navigator.of(context).push(
          //   AppTransitions.createSlideRoute(
          //     BookDetailsPage(bookListModel: book, bookUuid: book.id),
          //   ),
          // ),
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
          onTap: () => _navigateToCategory(context, category),
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

  void _navigateToCategory(BuildContext context, CategoryModel category) {
    // Navigation logic for categories would go here
    // This would need to analyze the category's navigationUrl and navigate accordingly
    Navigator.of(context).push(
      AppTransitions.createSlideRoute(
        DiscoverDetailsPage(title: category.title, fullPath: category.id),
      ),
    );
  }
}
