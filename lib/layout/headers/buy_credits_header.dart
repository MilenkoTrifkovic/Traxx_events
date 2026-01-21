import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class BuyCreditsHeader extends StatelessWidget {
  const BuyCreditsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.credit_card,
          color: AppColors.primaryAccent,
          size: 24,
        ),
        const SizedBox(width: 12),
        AppText.styledHeadingMedium(
          context,
          'Buy Credits',
          weight: FontWeight.w600,
        ),
      ],
    );
  }
}
