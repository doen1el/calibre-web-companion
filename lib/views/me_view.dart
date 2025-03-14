import 'package:calibre_web_companion/models/stats_model.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/view_models/me_view_model.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:calibre_web_companion/views/book_list.dart';
import 'package:calibre_web_companion/views/login_view.dart';
import 'package:calibre_web_companion/views/settings_view.dart';
import 'package:calibre_web_companion/views/shelfs_view.dart';
import 'package:calibre_web_companion/views/widgets/animated_counter.dart';
import 'package:calibre_web_companion/views/widgets/long_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginView()),
              );

              viewModel.logOut();
              homePageViewModel.setCurrentNavIndex(0);
            },
            icon: const Icon(Icons.logout),
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
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SettingsView()),
                    ),
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
                  ).push(MaterialPageRoute(builder: (context) => ShelfsView()));
                },
              ),
              LongButton(
                text: localizations.showReadBooks,
                icon: Icons.my_library_books_rounded,
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => BookList(
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
                      MaterialPageRoute(
                        builder:
                            (context) => BookList(
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

  /// Build a skeleton of the stats card
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  Widget _buildStatsSkeletonCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    // Create an animation controller in a stateless context
    final ValueNotifier<double> animationValue = ValueNotifier(0.0);

    // Animate the skeleton
    Future.delayed(Duration.zero, () {
      _animateSkeleton(animationValue);
    });

    return SizedBox(
      height: 364, // Same height as the actual content
      child: ValueListenableBuilder<double>(
        valueListenable: animationValue,
        builder: (context, value, _) {
          // Calculate the animation color based on the value
          final color = Color.lerp(Colors.grey[300], Colors.grey[100], value);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
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

              // Stats rows skeletons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRowSkeleton(context, color),
                    const Divider(),
                    _buildStatRowSkeleton(context, color),
                    const Divider(),
                    _buildStatRowSkeleton(context, color),
                    const Divider(),
                    _buildStatRowSkeleton(context, color),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Animates the skeleton effect
  ///
  /// Parameters:
  ///
  /// - `valueNotifier`: ValueNotifier
  void _animateSkeleton(ValueNotifier<double> valueNotifier) async {
    while (true) {
      // Forward animation
      for (double i = 0; i <= 1; i += 0.02) {
        valueNotifier.value = i;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Backward animation
      for (double i = 1; i >= 0; i -= 0.02) {
        valueNotifier.value = i;
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  /// Build a skeleton of a stat row
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `color`: Color
  Widget _buildStatRowSkeleton(BuildContext context, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon skeleton
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),

          // Label skeleton
          Expanded(
            child: Container(
              height: 18,
              width: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
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
      child:
          viewModel.isLoading
              ? _buildStatsSkeletonCard(context, localizations)
              : Column(
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
                  if (viewModel.errorMessage != null)
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
