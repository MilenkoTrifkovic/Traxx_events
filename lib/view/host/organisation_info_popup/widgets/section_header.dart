import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// A reusable header for the organisation info forms.
/// Height is fixed to 108 and it renders three stacked rows:
///  - icon (top)
///  - heading (AppText.styledHeadingLarge)
///  - description (AppText.styledBodyMedium)
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon row - 24px height
          SizedBox(
            height: 24,
            child: Icon(
              icon,
              size: 24,
            ),
          ),

          // Heading row - 40px height
          SizedBox(
            height: 40,
            child: AppText.styledHeadingLarge(context, title,
                weight: FontWeight.bold),
          ),

          // Description row - 20px height
          SizedBox(
            height: 20,
            child: AppText.styledBodyMedium(context, description,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
