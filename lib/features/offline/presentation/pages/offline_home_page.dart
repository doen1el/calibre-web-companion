import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/offline/presentation/pages/offline_library_page.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/connection_diagnostics_page.dart';
import 'package:calibre_web_companion/features/login/presentation/pages/login_page.dart';

class OfflineHomePage extends StatefulWidget {
  const OfflineHomePage({super.key});

  @override
  State<OfflineHomePage> createState() => _OfflineHomePageState();
}

class _OfflineHomePageState extends State<OfflineHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
      body: IndexedStack(
        index: _index,
        children: [
          _buildLibraryTab(context, localizations),
          const _OfflineMenu(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_rounded),
            label: localizations.books,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: localizations.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    return Column(
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
    );
  }
}

class _OfflineMenu extends StatelessWidget {
  const _OfflineMenu();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _MenuCard(
          icon: Icons.refresh_rounded,
          title: localizations.tryAgain,
          onTap: () => context.read<ConnectivityCubit>().recheck(),
        ),
        _MenuCard(
          icon: Icons.link_rounded,
          title: localizations.connectionSettings,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginSettingsPage()),
              ),
        ),
        _MenuCard(
          icon: Icons.troubleshoot_rounded,
          title: localizations.connectionDiagnostics,
          subtitle: localizations.connectionDiagnosticsSubtitle,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConnectionDiagnosticsPage(),
                ),
              ),
        ),
        _MenuCard(
          icon: Icons.manage_accounts_rounded,
          title: localizations.accounts,
          onTap:
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
