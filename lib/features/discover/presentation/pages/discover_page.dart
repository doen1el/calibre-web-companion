import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/shared/widgets/long_button_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/pages/discover_details_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => DiscoverBloc(),
      child: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, state) {
          return SafeArea(
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionHeader(context, localizations.discover),
                    _buildDiscoverWidget(context, localizations),
                    _buildSectionHeader(context, localizations.categories),
                    _buildCategoryWidget(context, localizations),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverWidget(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        LongButton(
          text: localizations.discover,
          icon: Icons.search,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.discoverBooks,
                discoverType: DiscoverType.discover,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.discoverBooks,
                  discoverType: DiscoverType.discover,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showHotBooks,
          icon: Icons.local_fire_department_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.hotBooks,
                discoverType: DiscoverType.hot,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.hotBooks,
                  discoverType: DiscoverType.hot,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showNewBooks,
          icon: Icons.new_releases_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.newBooks,
                discoverType: DiscoverType.newlyAdded,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.newBooks,
                  discoverType: DiscoverType.newlyAdded,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showRatedBooks,
          icon: Icons.star_border_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.ratedBooks,
                discoverType: DiscoverType.rated,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.ratedBooks,
                  discoverType: DiscoverType.rated,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryWidget(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        LongButton(
          text: localizations.showAuthors,
          icon: Icons.people_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.authors,
                categoryType: CategoryType.author,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.authors,
                  categoryType: CategoryType.author,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showCategories,
          icon: Icons.category_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.categories,
                categoryType: CategoryType.category,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.categories,
                  categoryType: CategoryType.category,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showSeries,
          icon: Icons.library_books_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.series,
                categoryType: CategoryType.series,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.series,
                  categoryType: CategoryType.series,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showFormats,
          icon: Icons.file_open_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.formats,
                categoryType: CategoryType.formats,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.formats,
                  categoryType: CategoryType.formats,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showLanguages,
          icon: Icons.language_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.languages,
                categoryType: CategoryType.language,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.languages,
                  categoryType: CategoryType.language,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showPublishers,
          icon: Icons.business_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.publishers,
                categoryType: CategoryType.publisher,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.publishers,
                  categoryType: CategoryType.publisher,
                ),
              ),
            );
          },
        ),
        LongButton(
          text: localizations.showRatings,
          icon: Icons.star_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.ratings,
                categoryType: CategoryType.ratings,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.ratings,
                  categoryType: CategoryType.ratings,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

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
