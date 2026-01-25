import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';
import 'package:calibre_web_companion/features/sync/bloc/sync_bloc.dart';
import 'package:calibre_web_companion/features/sync/bloc/sync_event.dart';
import 'package:calibre_web_companion/features/sync/bloc/sync_state.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/sync_filter_bottom_sheet.dart';

class SyncSettingsWidget extends StatefulWidget {
  const SyncSettingsWidget({super.key});

  @override
  State<SyncSettingsWidget> createState() => _SyncSettingsWidgetState();
}

class _SyncSettingsWidgetState extends State<SyncSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  localization.librarySync,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            BlocConsumer<SyncBloc, SyncState>(
              listener: (context, state) {
                if (state.status == SyncStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage ?? localization.syncError,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state.status == SyncStatus.completed) {
                  final errorCount =
                      state.queue
                          .where((item) => item.status == 'error')
                          .length;

                  if (errorCount > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localization.syncFinishedWithXErrors(errorCount),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localization.syncCompletedSuccessfully),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                switch (state.status) {
                  case SyncStatus.scanning:
                    return _buildScanningView(context, localization);
                  case SyncStatus.preview:
                    return _buildPreviewView(context, localization, state);
                  case SyncStatus.syncing:
                  case SyncStatus.paused:
                    return _buildLiveQueueView(context, localization, state);
                  case SyncStatus.completed:
                  case SyncStatus.error:
                  case SyncStatus.canceled:
                  case SyncStatus.initial:
                  case SyncStatus.idle:
                    return _buildIdleView(context, localization, state);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleView(
    BuildContext context,
    AppLocalizations localization,
    SyncState state, {
    String? message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          localization.syncDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _openConfigurationSheet(context, state),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sync,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  localization.configureAndSync,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningView(
    BuildContext context,
    AppLocalizations localization,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          localization.scanningLibraryAndApplyingFilters,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreviewView(
    BuildContext context,
    AppLocalizations localization,
    SyncState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            localization.foundXItemsToSync(state.previewBooks.length),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: state.previewBooks.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final book = state.previewBooks[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                visualDensity: VisualDensity.compact,
                title: Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  book.authors,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.book_outlined, size: 20),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.read<SyncBloc>().add(CancelSync()),
              child: Text(localization.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed:
                  () => context.read<SyncBloc>().add(ConfirmSyncFromPreview()),
              icon: const Icon(Icons.download),
              label: Text(localization.startSync),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveQueueView(
    BuildContext context,
    AppLocalizations localization,
    SyncState state,
  ) {
    final progress =
        state.totalBooksToCheck > 0
            ? state.syncedCount / state.totalBooksToCheck
            : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.syncing,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              "${state.syncedCount} / ${state.totalBooksToCheck} ($percentage%)",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),

        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: ListView.builder(
            itemCount: state.queue.length,
            itemBuilder: (context, index) {
              final item = state.queue[index];
              return _buildQueueItem(context, item);
            },
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: () => context.read<SyncBloc>().add(CancelSync()),
            child: Text(localization.stopSync),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(BuildContext context, SyncQueueItem item) {
    IconData icon;
    Color color;
    Widget? trailing;

    switch (item.status) {
      case 'done':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'downloading':
        icon = Icons.downloading;
        color = Theme.of(context).colorScheme.primary;
        trailing = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case 'error':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case 'pending':
      default:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
        break;
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        item.book.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color:
              item.status == 'pending'
                  ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .6)
                  : Theme.of(context).colorScheme.onSurface,
          fontWeight:
              item.status == 'downloading'
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
      trailing: trailing,
    );
  }

  Future<void> _openConfigurationSheet(
    BuildContext context,
    SyncState state,
  ) async {
    final currentFilter = state.filter;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => SafeArea(
            child: SyncFilterBottomSheet(initialFilter: currentFilter),
          ),
    );

    if (result != null && result is Map && context.mounted) {
      final filter = result['filter'] as SyncFilter;
      final dryRun = result['dryRun'] as bool;

      context.read<SyncBloc>().add(StartSync(filter, dryRun: dryRun));
    }
  }
}
