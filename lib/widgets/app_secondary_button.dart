import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';

/// Standardized primary button widget for the Traxx application
///
/// Features:
/// - Corner radius: 8px
/// - Background color: AppColors.primaryAccent
/// - Text color: AppColors.white
/// - Optional icon on the left side (white color)
/// - Consistent styling and behavior
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double borderRadius;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 44.0,
    this.padding,
    this.enabled = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.fontWeight,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = enabled && onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isButtonEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: textColor ?? AppColors.secondary,
            width: 1.4,
          ),
          foregroundColor: textColor ?? AppColors.secondary,
          backgroundColor: backgroundColor ?? Colors.transparent,

          // 🔥 ČINI DA SE PONAŠA KAO ELEVATED BUTTON
          minimumSize: Size(width ?? 0, height ?? 44),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.secondary,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? textColor ?? AppColors.secondary,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: Constants.font2,
                        fontSize: fontSize ?? Constants.bodyMediumFontSize,
                        fontWeight: fontWeight ?? FontWeight.w500,
                        height: Constants.bodyLineHeight,
                        color: textColor ?? AppColors.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
