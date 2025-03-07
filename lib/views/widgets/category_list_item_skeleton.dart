import 'package:flutter/material.dart';

class CategoryListItemSkeleton extends StatefulWidget {
  const CategoryListItemSkeleton({super.key});

  @override
  State<CategoryListItemSkeleton> createState() =>
      _CategoryListItemSkeletonState();
}

class _CategoryListItemSkeletonState extends State<CategoryListItemSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Colors.grey[100],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: borderRadius,
            child: Container(
              height: 56,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Title skeleton
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: _colorAnimation.value,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Arrow icon skeleton
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _colorAnimation.value,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
