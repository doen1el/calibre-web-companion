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
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/presentation/pages/magic_shelf_edit_page.dart';

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

          if (state.magicActionStatus == MagicShelfActionStatus.success) {
            final msg = switch (state.magicActionMessage) {
              'deleted' => localizations.magicShelfDeleted,
              'duplicated' => localizations.magicShelfDuplicated,
              'hidden' => localizations.magicShelfHidden,
              _ => '',
            };
            if (msg.isNotEmpty) context.showSnackBar(msg, isError: false);
          } else if (state.magicActionStatus == MagicShelfActionStatus.error) {
            context.showSnackBar(
              state.magicActionMessage ?? localizations.unknownError,
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

    return _buildContent(context, state, localizations);
  }

  Widget _buildContent(
    BuildContext context,
    ShelfViewState state,
    AppLocalizations localizations,
  ) {
    final bothEmpty = state.shelves.isEmpty && state.magicShelves.isEmpty;

    Widget addButton(String tooltip, VoidCallback onPressed) {
      return IconButton.filledTonal(
        icon: const Icon(Icons.add_rounded),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!state.isOpds)
          _buildSectionTitle(
            context,
            localizations.shelfs,
            trailing: addButton(
              localizations.createShelf,
              () => _showCreateShelfDialog(context, localizations),
            ),
          ),
        ...state.shelves.map(
          (shelf) => _buildShelfCard(context, shelf, localizations),
        ),
        if (state.supportsMagicShelves) ...[
          _buildSectionTitle(
            context,
            localizations.magicShelves,
            trailing: addButton(
              localizations.createMagicShelf,
              () => _openMagicShelfEditor(context),
            ),
          ),
          ...state.magicShelves.map(
            (shelf) => _buildMagicShelfCard(context, shelf, localizations),
          ),
        ],
        if (bothEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Center(
              child: Text(
                localizations.noShelvesFoundCreateOne,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _openMagicShelfEditor(BuildContext context, {String? shelfId}) {
    Navigator.of(context).push(
      AppTransitions.createSlideRoute(
        BlocProvider.value(
          value: context.read<ShelfViewBloc>(),
          child: MagicShelfEditPage(shelfId: shelfId),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildShelfCard(
    BuildContext context,
    ShelfViewModel shelf,
    AppLocalizations localizations,
  ) {
    final cleanTitle =
        shelf.title.endsWith(' (Public)')
            ? shelf.title.substring(0, shelf.title.length - 9)
            : shelf.title;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.list_rounded),
        title: Text(cleanTitle),
        trailing: _trailing(context, isPublic: shelf.isPublic),
        onTap: () {
          Navigator.of(context).push(
            AppTransitions.createSlideRoute(
              MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<ShelfViewBloc>()),
                  BlocProvider(create: (context) => getIt<ShelfDetailsBloc>()),
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
  }

  Widget _trailing(BuildContext context, {required bool isPublic}) {
    if (!isPublic) return const Icon(Icons.chevron_right_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.public_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }

  Widget _buildMagicShelfCard(
    BuildContext context,
    MagicShelfModel shelf,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading:
            shelf.icon != null
                ? Text(shelf.icon!, style: const TextStyle(fontSize: 24))
                : Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
        title: Text(shelf.name),
        trailing: _trailing(context, isPublic: shelf.isPublic),
        onTap: () {
          Navigator.of(context).push(
            AppTransitions.createSlideRoute(
              MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<ShelfViewBloc>()),
                  BlocProvider(create: (context) => getIt<ShelfDetailsBloc>()),
                ],
                child: ShelfDetailsPage(
                  shelfId: shelf.id,
                  shelfTitle: shelf.name,
                  isPublic: shelf.isPublic,
                  isMagic: true,
                  icon: shelf.icon,
                ),
              ),
            ),
          );
        },
      ),
    );
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
