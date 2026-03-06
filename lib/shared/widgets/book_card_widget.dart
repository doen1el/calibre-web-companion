import 'package:flutter/material.dart';

import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';

class BookCard extends StatelessWidget {
  final String bookId;
  final String title;
  final String authors;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? coverUrl;
  final bool readStatus;

  const BookCard({
    super.key,
    required this.bookId,
    required this.title,
    required this.authors,
    this.onTap,
    this.isLoading = false,
    this.coverUrl,
    this.readStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: isLoading ? null : onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: BookCoverWidget(
                bookId:
                    int.tryParse(bookId) ?? int.parse(bookId.split('/').last),
                coverUrl: coverUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            if (readStatus)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.8),
                  ),
                  padding: const EdgeInsets.all(0.5),
                  child: Icon(
                    Icons.check_circle,
                    size: 25,
                    color: Theme.of(context).colorScheme.primary,
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
                          Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.82),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authors,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .75),
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

            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .6),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
