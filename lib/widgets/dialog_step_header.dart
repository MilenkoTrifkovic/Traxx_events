import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class DialogStepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const DialogStepHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),

          // Vertical spacing
          AppSpacing.verticalXxxxs(context),

          // Title
          AppText.styledHeadingLarge(
            context,
            title,
            color: Theme.of(context).colorScheme.onSurface,
          ),

          // Vertical spacing
          AppSpacing.verticalXxxxs(context),

          // Description
          AppText.styledBodyMedium(
            context,
            description,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
