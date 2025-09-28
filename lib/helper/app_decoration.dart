import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class AppDecorations {
  static BoxDecoration formContainer(BuildContext context) {
    return BoxDecoration(
      color: AppColors.primaryContainer(context).withAlpha(64),
      borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
    );
  }

  static BoxDecoration bottomModal(BuildContext context) {
    return BoxDecoration(
      color: AppColors.primaryContainer(context).withAlpha(200),
      borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
    );
  }

  static BoxDecoration listDecoration(BuildContext context, {Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.primaryContainer(context).withAlpha(64),
      // border: Border.all(color: AppColors.onPrimaryContainer(context)),
      border: Border(
        top: BorderSide(color: AppColors.onPrimaryContainer(context)),
      ),
    );
  }

  static BoxDecoration bottomStickyButtonDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.background(context),
      boxShadow: [
        BoxShadow(
          color: AppColors.onBackground(context).withAlpha(25),
          blurRadius: 4,
          offset: const Offset(0, -4),
        ),
      ],
    );
  }
}
