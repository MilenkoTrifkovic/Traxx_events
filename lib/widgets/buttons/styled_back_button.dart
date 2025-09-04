import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// A reusable back button widget with customizable background and border radius.
///
/// By default, it shows a back arrow icon with a semi-transparent background.
/// The button handles navigation using the popRoute function.
class StyledBackButton extends StatelessWidget {
  /// Optional background color. If not provided, uses the default background color with 0.9 alpha
  final Color? backgroundColor;

  /// Optional icon color
  final Color? iconColor;

  /// Optional custom onPressed handler. If not provided, uses default popRoute
  final VoidCallback? onPressed;

  const StyledBackButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.radius(context, size: Sizes.lg),
        color: backgroundColor ??
            AppColors.background(context).withValues(alpha: 0.9),
      ),
      child: IconButton(
        onPressed: onPressed ?? () => popRoute(context),
        icon: Icon(
          Icons.arrow_back,
          color: iconColor,
        ),
      ),
    );
  }
}
