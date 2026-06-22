import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_event.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_state.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/book_view/presentation/pages/book_view_page.dart';
import 'package:calibre_web_companion/features/discover/presentation/pages/discover_page.dart';
import 'package:calibre_web_companion/features/me/presentation/pages/me_page.dart';
import 'package:calibre_web_companion/features/download_service/presentation/pages/download_service_page.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/offline/presentation/pages/offline_library_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, connectivity) {
        if (connectivity == ConnectivityStatus.offline) {
          return _buildOffline(context, localizations);
        }
        return _buildOnline(context, localizations);
      },
    );
  }

  Widget _buildOffline(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.offline),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: localizations.retry,
            onPressed: () => context.read<ConnectivityCubit>().recheck(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizations.offlineBannerMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: OfflineLibraryPage()),
        ],
      ),
    );
  }

  Widget _buildOnline(BuildContext context, AppLocalizations localizations) {
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
