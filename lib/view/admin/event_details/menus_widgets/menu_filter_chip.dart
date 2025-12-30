import 'package:flutter/material.dart';
import 'menu_constants.dart';

/// A filter chip widget for menu filtering options.
class MenuFilterChip extends StatelessWidget {
  /// The label text to display on the chip.
  final String label;

  /// The icon to display on the chip.
  final IconData icon;

  /// Whether the chip is currently selected.
  final bool selected;

  /// Callback when the chip is tapped.
  final VoidCallback onTap;

  const MenuFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kGfPurple : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? kGfPurple : kBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kGfPurple.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : kTextBody,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kTextDark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
