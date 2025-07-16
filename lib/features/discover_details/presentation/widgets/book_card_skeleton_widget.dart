import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/book_card_widget.dart';

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: BookCard(
        book: const DiscoverDetailsModel(
          id: 'skeleton',
          title: 'Loading Book Title',
          author: 'Loading Author Name',
        ),
      ),
    );
  }
}
