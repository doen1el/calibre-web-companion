import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/view_models/settings_view_mode.dart';
import 'package:calibre_web_companion/views/books_view.dart';
import 'package:calibre_web_companion/views/download_service_view.dart';
import 'package:calibre_web_companion/views/me_view.dart';
import 'package:calibre_web_companion/views/discover_view.dart';
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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book_rounded),
          label: localizations.books,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: localizations.discover,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: localizations.me,
        ),

        if (settingsViewModel.isDownloaderEnabled)
          BottomNavigationBarItem(
            icon: Icon(Icons.download_rounded),
            label: localizations.download,
          ),
      ],

      currentIndex: viewModel.currentNavIndex,
      onTap: (index) => viewModel.setCurrentNavIndex(index),
    );
  }
}
