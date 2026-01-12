import 'package:flutter/material.dart';

/// A small pill widget showing a count and label for menu summaries.
class MenuSummaryPill extends StatelessWidget {
  /// The count to display.
  final int count;

  /// The label text after the count.
  final String label;

  /// Background color for the pill.
  final Color color;

  const MenuSummaryPill({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
