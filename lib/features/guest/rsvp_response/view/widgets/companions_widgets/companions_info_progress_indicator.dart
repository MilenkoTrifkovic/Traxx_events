import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Progress indicator widget for companions information page
class CompanionsInfoProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;

  const CompanionsInfoProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledLabelMedium(
          context,
          'Progress: ${currentIndex + 1} of $totalSteps',
          weight: AppFontWeight.medium,
        ),
        AppSpacing.verticalSm(context),
        LinearProgressIndicator(
          value: (currentIndex + 1) / totalSteps,
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
        ),
      ],
    );
  }
}

