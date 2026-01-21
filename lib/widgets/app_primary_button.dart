import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final bool isLoading;

  /// Optional overrides
  final Color? backgroundColor; // solid color fallback
  final Color? textColor; // if set, overrides auto
  final Color? iconColor; // if set, overrides auto
  final double? fontSize;
  final FontWeight? fontWeight;
  final double borderRadius;

  /// Gradient support
  final Gradient? gradient;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 46.0,
    this.padding,
    this.enabled = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.fontWeight,
    this.borderRadius = 12.0,
    this.gradient,
  });

  // ✅ Compute luminance-safe foreground
  Color _autoForeground(Color bg) {
    // luminance: 0 (dark) -> 1 (light)
    final lum = bg.computeLuminance();
    return lum > 0.55 ? const Color(0xFF111827) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = enabled && onPressed != null && !isLoading;

    // Base gradient (if not provided)
    final Gradient usedGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent,
            AppColors.primaryAccent.withOpacity(0.82),
          ],
        );

    // Disabled gradient
    final Gradient disabledGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        (backgroundColor ?? AppColors.primaryAccent).withOpacity(0.45),
        (backgroundColor ?? AppColors.primaryAccent).withOpacity(0.30),
      ],
    );

    // ✅ Pick a representative background color for auto text color:
    // If gradient is used, take the first color; else use backgroundColor.
    Color bgForText;
    final Gradient activeGradient =
        isButtonEnabled ? usedGradient : disabledGradient;

    if (activeGradient is LinearGradient && activeGradient.colors.isNotEmpty) {
      bgForText = activeGradient.colors.first;
    } else {
      bgForText = backgroundColor ?? AppColors.primaryAccent;
    }

    // ✅ Auto foreground (unless user overrides)
    final fg = textColor ?? _autoForeground(bgForText);
    final ic = iconColor ?? fg;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: activeGradient,
          boxShadow: isButtonEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            hoverColor: Colors.white.withOpacity(0.06),
            splashColor: Colors.white.withOpacity(0.14),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Container(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),

                // Gloss overlay (kept, but slightly reduced so text stays crisp)
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isButtonEnabled ? 0.10 : 0.06),
                    Colors.transparent,
                  ],
                ),

                // Border adapts to fg (looks good on light + dark buttons)
                border: Border.all(
                  color: fg.withOpacity(isButtonEnabled ? 0.20 : 0.12),
                  width: 1,
                ),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: ic, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              text,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize:
                                    fontSize ?? Constants.bodyMediumFontSize,
                                fontWeight: fontWeight ?? FontWeight.w700,
                                letterSpacing: 0.2,
                                height: 1.1,
                                color: fg, // ✅ updated here
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
