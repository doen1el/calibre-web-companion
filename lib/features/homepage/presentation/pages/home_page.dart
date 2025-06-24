import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_event.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_state.dart';

import 'package:calibre_web_companion/features/book_view/presentation/pages/book_view_page.dart';

import 'package:calibre_web_companion/features/discover/presentation/pages/discover_page.dart';
import 'package:calibre_web_companion/features/me/presentation/pages/me_page.dart';
import 'package:calibre_web_companion/features/download_service/presentation/pages/download_service_page.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, homeState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen:
              (previous, current) =>
                  previous.isDownloaderEnabled != current.isDownloaderEnabled,
          builder: (context, settingsState) {
            if (!settingsState.isDownloaderEnabled &&
                homeState.currentNavIndex == 3) {
              context.read<HomePageBloc>().add(const ChangeNavIndex(0));
            }

            return Scaffold(
              body: IndexedStack(
                index: homeState.currentNavIndex,
                children: [
                  const BookViewPage(),
                  const DiscoverPage(),
                  const MePage(),
                  if (settingsState.isDownloaderEnabled)
                    const DownloadServicePage(),
                ],
              ),
              bottomNavigationBar: _buildBottomNavigation(
                context,
                localizations,
                homeState,
                settingsState,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    AppLocalizations localizations,
    HomePageState homeState,
    SettingsState settingsState,
  ) {
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.book_rounded),
        label: localizations.books,
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_rounded),
        label: localizations.discover,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_rounded),
        label: localizations.me,
      ),
    ];

    if (settingsState.isDownloaderEnabled) {
      destinations.add(
        NavigationDestination(
          icon: const Icon(Icons.download_rounded),
          label: localizations.download,
        ),
      );
    }

    return NavigationBar(
      destinations: destinations,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: homeState.currentNavIndex,
      onDestinationSelected:
          (index) => context.read<HomePageBloc>().add(ChangeNavIndex(index)),
    );
  }
}
