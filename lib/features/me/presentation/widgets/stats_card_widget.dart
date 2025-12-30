import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/me/presentation/widgets/animated_counter_widget.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class StatsCard extends StatelessWidget {
  final StatsModel stats;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool isOpds;

  const StatsCard({
    super.key,
    required this.stats,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
    this.isOpds = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Skeletonizer(
        enabled: isLoading,
        containersColor: Theme.of(context).colorScheme.surface,
        effect: ShimmerEffect(
          baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          highlightColor: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
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

                  if (!isOpds) ...[
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
                ],
              ),
            ),
            if (errorMessage != null && !isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.retry),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
