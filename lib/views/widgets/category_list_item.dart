import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';

class CategoryListItem extends StatelessWidget {
  final CategoryItem category;
  final CategoryType type;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child:
                      type == CategoryType.ratings
                          ? _buildRatingStars(context, category.title)
                          : Text(
                            category.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Extract the rating value from the category title
  ///
  /// Parameters:
  ///
  /// - `title`: The title of the category
  double _extractRating(String title) {
    final RegExp regex = RegExp(r'(\d+[.,]?\d*)');
    final match = regex.firstMatch(title);
    if (match != null) {
      final String number = match.group(1)!.replaceAll(',', '.');
      try {
        return double.parse(number);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Build star rating widget based on the title
  ///
  /// Parameters:
  ///
  /// - `context`: The build context
  /// - `title`: The title of the category
  Widget _buildRatingStars(BuildContext context, String title) {
    final double rating = _extractRating(title);
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < fullStars
                ? Icons.star
                : (i == fullStars && hasHalfStar)
                ? Icons.star_half
                : Icons.star_border,
            size: 20,
            color: Colors.amber,
          ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
