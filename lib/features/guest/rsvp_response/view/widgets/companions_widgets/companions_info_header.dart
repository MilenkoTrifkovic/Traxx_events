import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Header widget for the companions information page
class CompanionsInfoHeader extends StatelessWidget {
  final int totalCompanionsCount;
  final int savedCount;
  final int remainingCount;

  const CompanionsInfoHeader({
    super.key,
    required this.totalCompanionsCount,
    required this.savedCount,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledHeadingLarge(
          context,
          'Guest Information',
          weight: AppFontWeight.bold,
        ),
        AppSpacing.verticalSm(context),
        AppText.styledBodyLarge(
          context,
          savedCount > 0
              ? 'You have already added $savedCount guest${savedCount > 1 ? 's' : ''}. '
                  'Please provide information for your remaining $remainingCount guest${remainingCount > 1 ? 's' : ''}.'
              : 'Please provide information for your $totalCompanionsCount guest${totalCompanionsCount > 1 ? 's' : ''}.',
        ),
      ],
    );
  }
}
