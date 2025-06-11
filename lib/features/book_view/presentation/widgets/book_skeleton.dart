import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/book_card.dart';

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyBook = BookViewModel(
      id: 0,
      uuid: 'skeleton-uuid',
      title: 'Skeleton Book Title',
      authors: 'Skeleton Author',
    );

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        // ignore: deprecated_member_use
        baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        // ignore: deprecated_member_use
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
      child: BookCard(book: dummyBook),
    );
  }
}
