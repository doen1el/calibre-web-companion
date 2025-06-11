import '../view_models/homepage_view_model.dart';
import '../view_models/settings_view_mode.dart';
import 'books_view.dart';
import 'download_service_view.dart';
import 'me_view.dart';
import 'discover_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomepageView extends StatelessWidget {
  const HomepageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomepageViewModel>();
    final settingsViewModel = context.watch<SettingsViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body:
          [
            BooksView(),
            DiscoverView(),
            MeView(),
            DownloadServiceView(),
          ][viewModel.currentNavIndex],
      bottomNavigationBar: _buildBottomNavigation(
        context,
        localizations,
        viewModel,
        settingsViewModel,
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    AppLocalizations localizations,
    HomepageViewModel viewModel,
    SettingsViewModel settingsViewModel,
  ) {
    NavigationDestinationLabelBehavior labelBehavior =
        NavigationDestinationLabelBehavior.alwaysShow;

    return NavigationBar(
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.book_rounded),
          label: localizations.books,
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: localizations.discover,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_rounded),
          label: localizations.me,
        ),

        if (settingsViewModel.isDownloaderEnabled)
          NavigationDestination(
            icon: Icon(Icons.download_rounded),
            label: localizations.download,
          ),
      ],
      labelBehavior: labelBehavior,

      selectedIndex: viewModel.currentNavIndex,
      onDestinationSelected: (index) => viewModel.setCurrentNavIndex(index),
    );
  }
}
