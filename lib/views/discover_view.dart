import 'package:calibre_web_companion/utils/app_transition.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/views/book_list.dart';
import 'package:calibre_web_companion/views/book_recommendation.dart';
import 'package:calibre_web_companion/views/widgets/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            _buildSectionHeader(context, localizations.discover),
            _buildDiscoverWidget(context, localizations),
            _buildSectionHeader(context, localizations.categories),
            _buildCategoryWidget(context, localizations),
          ],
        ),
      ),
    );
  }

  /// Build the discover section
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  Widget _buildDiscoverWidget(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        LongButton(
          text: localizations.recommendations,
          icon: Icons.star_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(BookRecommendationsView()),
              ),
        ),
        LongButton(
          text: localizations.discover,
          icon: Icons.search,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.discoverBooks,
                    bookListType: BookListType.discover,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showHotBooks,
          icon: Icons.local_fire_department_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.hotBooks,
                    bookListType: BookListType.hot,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showNewBooks,
          icon: Icons.new_releases_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.newBooks,
                    bookListType: BookListType.newlyAdded,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showRatedBooks,
          icon: Icons.star_border_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.ratedBooks,
                    bookListType: BookListType.rated,
                  ),
                ),
              ),
        ),
      ],
    );
  }

  /// Build the category section
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  Widget _buildCategoryWidget(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        LongButton(
          text: localizations.showAuthors,
          icon: Icons.people_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.authors,
                    categoryType: CategoryType.author,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showCategories,
          icon: Icons.category_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.categories,
                    categoryType: CategoryType.category,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showSeries,
          icon: Icons.library_books_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.series,
                    categoryType: CategoryType.series,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showFormats,
          icon: Icons.file_open_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.formats,
                    categoryType: CategoryType.formats,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showLanguages,
          icon: Icons.language_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.languages,
                    categoryType: CategoryType.language,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showPublishers,
          icon: Icons.business_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.publishers,
                    categoryType: CategoryType.publisher,
                  ),
                ),
              ),
        ),
        LongButton(
          text: localizations.showRatings,
          icon: Icons.star_rounded,
          onPressed:
              () => Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  BookList(
                    title: localizations.ratings,
                    categoryType: CategoryType.ratings,
                  ),
                ),
              ),
        ),
      ],
    );
  }

  /// Build the section header
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: Theme.of(context).colorScheme.primaryContainer,
            thickness: 2,
          ),
        ],
      ),
    );
  }
}
