import 'package:calibre_web_companion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/me/bloc/me_event.dart';
import 'package:calibre_web_companion/features/me/bloc/me_state.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';

import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/me/presentation/widgets/stats_card_widget.dart';
import 'package:calibre_web_companion/shared/widgets/long_button_widget.dart';
import 'package:calibre_web_companion/features/login/presentation/pages/login_page.dart';
import 'package:calibre_web_companion/features/settings/presentation/pages/settings_page.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/presentation/pages/shelf_view_page.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/pages/discover_details_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<MeBloc>()..add(const LoadStats()),

      child: BlocConsumer<MeBloc, MeState>(
        listener: (context, state) {
          if (state.status == MeStatus.error) {
            context.showSnackBar(
              "${localizations.error}: ${state.errorMessage}",
              isError: true,
            );
          }

          if (state.logoutStatus == LogoutStatus.success) {
            Navigator.of(
              // ignore: use_build_context_synchronously
              context,
            ).pushReplacement(
              AppTransitions.createSlideRoute(const LoginPage()),
            );
          } else if (state.logoutStatus == LogoutStatus.error) {
            context.showSnackBar(
              "${localizations.logoutFailed}: ${state.errorMessage}",
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(localizations.me),
              actions: [
                IconButton(
                  onPressed: () {
                    _showLogOutDialog(context, localizations);
                  },
                  icon: const Icon(Icons.logout),
                  tooltip: localizations.logout,
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<MeBloc>().add(const LoadStats());
                return;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    StatsCard(
                      stats: state.stats ?? const StatsModel(),
                      isLoading: state.status == MeStatus.loading,
                      errorMessage:
                          state.status == MeStatus.error
                              ? state.errorMessage
                              : null,
                      onRetry:
                          () => context.read<MeBloc>().add(const LoadStats()),
                      isOpds: state.isOpds,
                    ),
                    LongButton(
                      text: localizations.settings,
                      icon: Icons.settings_rounded,
                      onPressed:
                          () => Navigator.of(context).push(
                            AppTransitions.createSlideRoute(SettingsPage()),
                          ),
                    ),
                    LongButton(
                      text: localizations.shelfs,
                      icon: Icons.list_rounded,
                      onPressed:
                          () => Navigator.of(context).push(
                            AppTransitions.createSlideRoute(ShelfViewPage()),
                          ),
                    ),

                    if (!state.isOpds) ...[
                      LongButton(
                        text: localizations.showReadBooks,
                        icon: Icons.my_library_books_rounded,
                        onPressed:
                            () => Navigator.of(context).push(
                              AppTransitions.createSlideRoute(
                                DiscoverDetailsPage(
                                  title: localizations.readBooks,
                                  discoverType: DiscoverType.readbooks,
                                  fullPath: "/opds/readbooks",
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
                                DiscoverDetailsPage(
                                  title: localizations.unreadBooks,
                                  discoverType: DiscoverType.unreadbooks,
                                  fullPath: "/opds/unreadbooks",
                                ),
                              ),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogOutDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(localizations.logout),
            content: Text(localizations.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<LoginBloc>().add(const LoginLogOut());

                  context.read<MeBloc>().add(const LogOut());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Text(
                  localizations.logout,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
