import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

class EmailVerificationInfoPanel extends StatelessWidget {
  const EmailVerificationInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: AppPadding.left(context, paddingType: Sizes.xl),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: AppColors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),
              AppText.styledHeadingLarge(
                family: Constants.font2,
                weight: FontWeight.bold,
                context,
                'Check Your Email',
                color: AppColors.white,
              ),
              SectionDivider(
                height: 30,
                thickness: 2,
                color: AppColors.white,
              ),
              AppText.styledHeadingMedium(
                weight: FontWeight.w500,
                context,
                'Verify your email address to access your Trax Event dashboard and start creating amazing events.',
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
