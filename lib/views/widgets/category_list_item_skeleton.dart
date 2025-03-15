import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/views/widgets/category_list_item.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryListItemSkeleton extends StatelessWidget {
  const CategoryListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy-Kategorie für das Skeleton erstellen
    final dummyCategory = CategoryItem(
      id: 'skeleton-id',
      title: 'Beispiel-Kategorie',
      navigationUrl: '',
    );

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        // ignore: deprecated_member_use
        baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        // ignore: deprecated_member_use
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
      child: CategoryListItem(
        category: dummyCategory,
        type: CategoryType.author,
        onTap: () {},
      ),
    );
  }
}
