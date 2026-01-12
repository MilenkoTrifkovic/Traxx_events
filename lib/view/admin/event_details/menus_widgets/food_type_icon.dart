import 'package:flutter/material.dart';

/// A small icon indicating vegetarian/non-vegetarian food type.
/// 
/// This matches the original implementation used in GuestMenuSelectionPage.
class FoodTypeIcon extends StatelessWidget {
  /// Whether the food item is vegetarian.
  /// - `true` = vegetarian (green)
  /// - `false` = non-vegetarian (red)
  /// - `null` = unknown (grey)
  final bool? isVeg;

  const FoodTypeIcon({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final Color c = isVeg == true
        ? Colors.green.shade600
        : isVeg == false
            ? Colors.red.shade600
            : Colors.grey.shade500;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c, width: 2),
        color: c.withOpacity(0.12),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
      ),
    );
  }
}
