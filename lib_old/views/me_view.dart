import '../models/stats_model.dart';
import '../utils/app_transition.dart';
import '../utils/snack_bar.dart';
import '../view_models/book_list_view_model.dart';
import '../view_models/homepage_view_model.dart';
import '../view_models/me_view_model.dart';
import '../view_models/shelf_view_model.dart';
import 'book_list.dart';
import 'login_view.dart';
import 'settings_view.dart';
import 'shelfs_view.dart';
import 'widgets/animated_counter.dart';
import 'widgets/long_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MeView extends StatefulWidget {
  const MeView({super.key});

  @override
  State<MeView> createState() => MeViewState();
}

class MeViewState extends State<MeView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MeViewModel>();
    final homePageViewModel = context.watch<HomepageViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    if (viewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showSnackBar(
          "${localizations.error}: ${viewModel.errorMessage}",
          isError: true,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.me),
        actions: [
          IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.remove("calibre_web_session");

              Navigator.of(
                // ignore: use_build_context_synchronously
                context,
              ).pushReplacement(AppTransitions.createSlideRoute(LoginView()));

              viewModel.logOut();
              homePageViewModel.setCurrentNavIndex(0);
            },
            icon: const Icon(Icons.logout),
            tooltip: localizations.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.getStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStatsWidget(context, localizations, viewModel),
              LongButton(
                text: localizations.settings,
                icon: Icons.settings_rounded,
                onPressed:
                    () => Navigator.of(
                      context,
                    ).push(AppTransitions.createSlideRoute(SettingsView())),
              ),
              LongButton(
                text: localizations.shelfs,
                icon: Icons.list_rounded,
                onPressed: () async {
                  final shelfViewModel = context.read<ShelfViewModel>();
                  await shelfViewModel.loadShelfs();
                  Navigator.of(
                    // ignore: use_build_context_synchronously
                    context,
                  ).push(AppTransitions.createSlideRoute(ShelfsView()));
                },
              ),
              LongButton(
                text: localizations.showReadBooks,
                icon: Icons.my_library_books_rounded,
                onPressed:
                    () => Navigator.of(context).push(
                      AppTransitions.createSlideRoute(
                        BookList(
                          title: localizations.readBooks,
                          bookListType: BookListType.readbooks,
                        ),
                      ),
                    ),
              ),
              LongButton(
                text: localizations.showUnReadBooks,
                icon: Icons.read_more_rounded,
                onPressed:
                    () => Navigator.of(context).push(
                      AppTransitions.createSlideRoute(
                        BookList(
                          title: localizations.unreadBooks,
                          bookListType: BookListType.unreadbooks,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the stats widget
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `viewModel`: MeViewModel
  Widget _buildStatsWidget(
    BuildContext context,
    AppLocalizations localizations,
    MeViewModel viewModel,
  ) {
    final stats = viewModel.stats ?? StatsModel();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Skeletonizer(
        enabled: viewModel.isLoading,
        containersColor: Theme.of(context).colorScheme.surface,
        effect: ShimmerEffect(
          baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          highlightColor: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                localizations.libraryStatistics,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    Icons.book,
                    localizations.books,
                    stats.books.toString(),
                  ),
                  const Divider(),
                  _buildStatRow(
                    context,
                    Icons.person,
                    localizations.authors,
                    stats.authors.toString(),
                  ),
                  const Divider(),
                  _buildStatRow(
                    context,
                    Icons.category,
                    localizations.categories,
                    stats.categories.toString(),
                  ),
                  const Divider(),
                  _buildStatRow(
                    context,
                    Icons.collections_bookmark,
                    localizations.series,
                    stats.series.toString(),
                  ),
                ],
              ),
            ),
            if (viewModel.errorMessage != null && !viewModel.isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => viewModel.getStats(),
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.retry),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a stat row
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `icon`: IconData
  /// - `label`: String
  /// - `value`: String
  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          AnimatedCounter(
            value: value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
