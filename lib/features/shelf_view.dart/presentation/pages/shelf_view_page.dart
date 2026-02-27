import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/app_skeletonizer.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/presentation/widgets/create_shelf_dialog_widget.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/shelf_details/presentation/pages/shelf_details_page.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';

class ShelfViewPage extends StatelessWidget {
  const ShelfViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<ShelfViewBloc>()..add(const LoadShelves()),
      child: BlocConsumer<ShelfViewBloc, ShelfViewState>(
        listener: (context, state) {
          if (state.createShelfStatus == CreateShelfStatus.success) {
            context.showSnackBar(
              localizations.shelfSuccessfullyCreated,
              isError: false,
            );
          } else if (state.createShelfStatus == CreateShelfStatus.error) {
            context.showSnackBar(state.errorMessage.toString(), isError: true);
          }

          if (state.status == ShelfViewStatus.error) {
            context.showSnackBar(
              "${localizations.errorLoadingData}: ${state.errorMessage}",
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.shelfs)),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ShelfViewBloc>().add(const LoadShelves());
              },
              child: _buildBody(context, state, localizations),
            ),
            floatingActionButton:
                state.isOpds
                    ? null
                    : FloatingActionButton.extended(
                      onPressed:
                          () => _showCreateShelfDialog(context, localizations),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded),
                          const SizedBox(width: 8),
                          Text(localizations.createShelf),
                        ],
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ShelfViewState state,
    AppLocalizations localizations,
  ) {
    if (state.status == ShelfViewStatus.loading) {
      return _buildLoadingSkeleton(context);
    }

    if (state.status == ShelfViewStatus.error) {
      return _buildErrorWidget(context, state, localizations);
    }

    if (state.shelves.isEmpty) {
      return _buildEmptyState(context, localizations);
    }

    return _buildShelfsList(context, state, localizations);
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.list_rounded),
              title: Text("Loading Shelf Title"),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    ShelfViewState state,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.errorLoadingData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(state.errorMessage ?? localizations.unknownError),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => context.read<ShelfViewBloc>().add(const LoadShelves()),
            child: Text(localizations.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_rounded,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: .5),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noShelvesFoundCreateOne,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildShelfsList(
    BuildContext context,
    ShelfViewState state,
    AppLocalizations localizations,
  ) {
    return ListView.builder(
      itemCount: state.shelves.length,
      itemBuilder: (context, index) {
        final shelf = state.shelves[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.list_rounded),
            title: Text(shelf.title),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              String cleanTitle = shelf.title;
              if (shelf.isPublic && cleanTitle.endsWith(' (Public)')) {
                cleanTitle = cleanTitle.substring(0, cleanTitle.length - 9);
              }

              Navigator.of(context).push(
                AppTransitions.createSlideRoute(
                  MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<ShelfViewBloc>()),
                      BlocProvider(
                        create: (context) => getIt<ShelfDetailsBloc>(),
                      ),
                    ],
                    child: ShelfDetailsPage(
                      shelfId: shelf.id,
                      shelfTitle: cleanTitle,
                      isPublic: shelf.isPublic,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateShelfDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => CreateShelfDialog(
            onCreateShelf: (shelfName, isPublic) {
              context.read<ShelfViewBloc>().add(
                CreateShelf(shelfName, isPublic: isPublic),
              );
            },
          ),
    );
  }
}
