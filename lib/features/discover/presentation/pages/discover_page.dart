import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_state.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:calibre_web_companion/features/settings/data/models/discover_layout_config.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/shared/widgets/long_button_widget.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/pages/discover_details_page.dart';
import 'package:calibre_web_companion/features/settings/presentation/pages/settings_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<DiscoverBloc>(),
      child: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, state) {
          final settingsState = context.select(
            (SettingsBloc bloc) => bloc.state,
          );

          return SafeArea(
            child: Scaffold(
              body: SingleChildScrollView(
                child:
                    state.isOpds
                        ? _buildOpdsBody(context, localizations)
                        : _buildConfiguredBody(
                          context,
                          localizations,
                          settingsState,
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpdsBody(BuildContext context, AppLocalizations localizations) {
    return Column(
      children: [
        _buildSectionHeader(context, localizations.libraries),
        LongButton(
          text: localizations.browsLibraries,
          icon: Icons.library_books_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.libraries,
                categoryType: CategoryType.libraries,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.libraries,
                  categoryType: CategoryType.libraries,
                ),
              ),
            );
          },
        ),
        _buildSectionHeader(context, localizations.discover),
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
          text: localizations.surpriseMe,
          icon: Icons.shuffle_rounded,
          onPressed: () {
            context.read<DiscoverBloc>().add(
              NavigateToBookList(
                title: localizations.surpriseMe,
                discoverType: DiscoverType.surprise,
              ),
            );
            Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                DiscoverDetailsPage(
                  title: localizations.surpriseMe,
                  discoverType: DiscoverType.surprise,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfiguredBody(
    BuildContext context,
    AppLocalizations localizations,
    SettingsState settingsState,
  ) {
    final orderedMainSections = DiscoverLayoutConfig.normalizeMainSectionsOrder(
      settingsState.discoverMainSectionsOrder,
    );
    final enabledMainSections =
        DiscoverLayoutConfig.normalizeEnabledMainSections(
          settingsState.enabledDiscoverMainSections,
        ).toSet();

    final discoverButtons = _buildDiscoverButtons(
      context,
      localizations,
      settingsState,
    );
    final categoryButtons = _buildCategoryButtons(
      context,
      localizations,
      settingsState,
    );

    final sections = <Widget>[];

    for (final mainSectionKey in orderedMainSections) {
      if (!enabledMainSections.contains(mainSectionKey)) continue;

      if (mainSectionKey == DiscoverMainSection.discover.key &&
          discoverButtons.isNotEmpty) {
        sections.add(_buildSectionHeader(context, localizations.discover));
        sections.add(Column(children: discoverButtons));
      }

      if (mainSectionKey == DiscoverMainSection.categories.key &&
          categoryButtons.isNotEmpty) {
        sections.add(_buildSectionHeader(context, localizations.categories));
        sections.add(Column(children: categoryButtons));
      }
    }

    if (sections.isEmpty) {
      return _buildDiscoverDisabledFallback(context, localizations);
    }

    return Column(children: sections);
  }

  List<Widget> _buildDiscoverButtons(
    BuildContext context,
    AppLocalizations localizations,
    SettingsState settingsState,
  ) {
    final orderedItems = DiscoverLayoutConfig.normalizeDiscoverItemsOrder(
      settingsState.discoverItemsOrder,
    );
    final enabledItems =
        DiscoverLayoutConfig.normalizeEnabledDiscoverItems(
          settingsState.enabledDiscoverItems,
        ).toSet();

    final builders = <String, Widget Function()>{
      DiscoverItem.discover.key:
          () => LongButton(
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
      DiscoverItem.hotBooks.key:
          () => LongButton(
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
      DiscoverItem.newBooks.key:
          () => LongButton(
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
      DiscoverItem.ratedBooks.key:
          () => LongButton(
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
    };

    return orderedItems
        .where((itemKey) => enabledItems.contains(itemKey))
        .where((itemKey) => builders.containsKey(itemKey))
        .map((itemKey) => builders[itemKey]!())
        .toList();
  }

  List<Widget> _buildCategoryButtons(
    BuildContext context,
    AppLocalizations localizations,
    SettingsState settingsState,
  ) {
    final orderedItems = DiscoverLayoutConfig.normalizeCategoryItemsOrder(
      settingsState.categoryItemsOrder,
    );
    final enabledItems =
        DiscoverLayoutConfig.normalizeEnabledCategoryItems(
          settingsState.enabledCategoryItems,
        ).toSet();

    final builders = <String, Widget Function()>{
      CategoryItem.authors.key:
          () => LongButton(
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
      CategoryItem.categories.key:
          () => LongButton(
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
      CategoryItem.series.key:
          () => LongButton(
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
      CategoryItem.formats.key:
          () => LongButton(
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
      CategoryItem.languages.key:
          () => LongButton(
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
      CategoryItem.publishers.key:
          () => LongButton(
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
      CategoryItem.ratings.key:
          () => LongButton(
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
    };

    return orderedItems
        .where((itemKey) => enabledItems.contains(itemKey))
        .where((itemKey) => builders.containsKey(itemKey))
        .map((itemKey) => builders[itemKey]!())
        .toList();
  }

  Widget _buildDiscoverDisabledFallback(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              localizations.discoverAllSectionsDisabledTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.discoverAllSectionsDisabledDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  AppTransitions.createSlideRoute(
                    const SettingsPage(
                      initialSubPage: SettingsSubPage.discover,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings_rounded),
              label: Text(localizations.settings),
            ),
          ],
        ),
      ),
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
