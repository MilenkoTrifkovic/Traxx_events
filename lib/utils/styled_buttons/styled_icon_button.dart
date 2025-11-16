import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// A customizable styled icon button that maintains consistent design across the app.
///
/// Required parameters:
/// - [icon]: The icon to display in the button
/// - [onPressed]: Callback function when button is pressed
///
/// Optional parameters allow customization of size, colors, and appearance.
class StyledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double? iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? hoverColor;
  final String? tooltip;
  final bool hasBorder;
  final EdgeInsets? padding;
  final Sizes borderRadius;
  final bool hasShadow;
  final double? elevation;
  final Color? shadowColor;

  const StyledIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24.0,
    this.iconColor,
    this.backgroundColor,
    this.hoverColor,
    this.tooltip,
    this.hasBorder = false,
    this.padding,
    this.borderRadius = Sizes.sm,
    this.hasShadow = false,
    this.elevation = 2.0,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        elevation: hasShadow ? elevation ?? 0 : 0,
        shadowColor: shadowColor ?? Colors.black.withOpacity(0.3),
        borderRadius: AppBorderRadius.radius(context, size: borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppBorderRadius.radius(context, size: borderRadius),
          hoverColor:
              hoverColor ?? AppColors.primaryOld(context).withOpacity(0.1),
          child: Container(
            padding: padding ?? AppPadding.all(context, paddingType: Sizes.sm),
            decoration: BoxDecoration(
              // color: backgroundColor ?? Colors.transparent,
              border: hasBorder
                  ? Border.all(
                      color: AppColors.outline(context),
                      width: 1.0,
                    )
                  : null,
              borderRadius: AppBorderRadius.radius(context, size: borderRadius),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.onBackground(context),
            ),
          ),
        ),
      ),
    );
  }
}
