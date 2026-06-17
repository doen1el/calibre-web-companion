import 'package:flutter/material.dart';

const highlightColors = [
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF81C784), // Green
  Color(0xFF64B5F6), // Blue
  Color(0xFFE57373), // Red
  Color(0xFFFFAB91), // Orange
  Color(0xFFCE93D8), // Purple
];

class HighlightToolbar extends StatelessWidget {
  final VoidCallback onDismiss;
  final Function(Color color) onColorSelected;

  const HighlightToolbar({
    super.key,
    required this.onDismiss,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...highlightColors.map((color) => GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                  ),
                )),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.white54, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
