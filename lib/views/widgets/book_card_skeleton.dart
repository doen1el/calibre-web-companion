import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/views/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyBook = BookItem(
      id: 'skeleton-id',
      uuid: 'skeleton-uuid',
      title: 'Skeleton Book Title',
      author: 'Skeleton Author',
      summary: 'Skeleton Summary',
      formats: ['EPUB', 'PDF'],
      categories: ['Fiction'],
      language: 'eng',
      fileSize: 1500000,
      published: DateTime.now(),
      updated: DateTime.now(),
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
