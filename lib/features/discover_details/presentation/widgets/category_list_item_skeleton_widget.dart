import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/presentation/widgets/category_list_item_widget.dart';

class CategoryListItemSkeleton extends StatelessWidget {
  const CategoryListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: CategoryListItem(
        category: const CategoryModel(
          id: 'skeleton-id',
          title: 'Loading Category Name',
        ),
        type: CategoryType.category,
        onTap: () {},
      ),
    );
  }
}
