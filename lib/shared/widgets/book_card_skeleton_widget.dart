import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
        highlightColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: .4),
      ),
      child: BookCard(
        bookId: "0",
        title: "Skeleton Book Title",
        authors: "Skeleton author",
      ),
    );
  }
}
