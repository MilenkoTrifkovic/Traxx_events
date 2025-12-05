import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class FirstSectionUserCard extends StatelessWidget {
  final UserModel user;

  const FirstSectionUserCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: AppPadding.horizontal(context, paddingType: Sizes.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledBodyLarge(
                    context,
                    user.email,
                    weight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // AppSpacing.horizontalXxs(context),
                  AppText.styledBodyMedium(
                    context,
                    color: AppColors.textMuted,
                    user.role.name,
                    weight: AppFontWeight.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //status
                  // AppText.styledBodySmall(
                  //     context, event.status.toLowerCase())
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a 48x48 placeholder widget with a wine glass icon
  /// when the event has no cover image or if image loading fails
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.background(context),
      child: const Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 24,
          color: Colors.red,
        ),
      ),
    );
  }
}
