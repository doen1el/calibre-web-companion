import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';

class SeriesFolderCard extends StatelessWidget {
  final String seriesName;

  final List<BookViewModel> books;
  final VoidCallback? onTap;

  const SeriesFolderCard({
    super.key,
    required this.seriesName,
    required this.books,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final borderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: scheme.surfaceContainerHighest),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 72),
            child: seriesFan(context, books),
          ),

          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.folder_rounded,
                size: 15,
                color: scheme.onPrimary,
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        scheme.surface.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  color: scheme.surface.withValues(alpha: 0.82),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seriesName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${books.length} ${localizations.books}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(borderRadius: borderRadius, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class SeriesFolderListTile extends StatelessWidget {
  final String seriesName;
  final List<BookViewModel> books;
  final VoidCallback? onTap;

  const SeriesFolderListTile({
    super.key,
    required this.seriesName,
    required this.books,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {},
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRect(
                  child: Container(
                    color: scheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(10),
                    child: seriesFan(context, books),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              seriesName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${books.length} ${localizations.books}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget seriesFan(BuildContext context, List<BookViewModel> books) {
  final covers = books.take(3).toList();
  if (covers.isEmpty) {
    return Icon(
      Icons.menu_book_rounded,
      size: 40,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final coverWidth = constraints.maxWidth * 0.66;
      final coverHeight = (coverWidth * 1.5).clamp(0.0, constraints.maxHeight);

      final last = covers.length - 1;
      final maxDx = last * (coverWidth * 0.16);
      final maxDy = -last * (coverHeight * 0.05);

      final children = <Widget>[];
      for (int j = covers.length - 1; j >= 0; j--) {
        final angle = j * 0.14;
        final dx = j * (coverWidth * 0.16) - maxDx / 2;
        final dy = -j * (coverHeight * 0.05) - maxDy / 2;

        children.add(
          Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: _coverTile(
                context,
                covers[j],
                coverWidth,
                coverHeight,
                dimmed: j != 0,
              ),
            ),
          ),
        );
      }

      return Center(
        child: Stack(alignment: Alignment.center, children: children),
      );
    },
  );
}

Widget _coverTile(
  BuildContext context,
  BookViewModel book,
  double width,
  double height, {
  required bool dimmed,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: scheme.surface, width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    foregroundDecoration:
        dimmed
            ? BoxDecoration(color: Colors.black.withValues(alpha: 0.28))
            : null,
    child: BookCoverWidget(
      bookId: book.id,
      coverUrl: book.coverUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    ),
  );
}
