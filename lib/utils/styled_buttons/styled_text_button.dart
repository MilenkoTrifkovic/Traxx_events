import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';

class StyledTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isPrimary;
  final bool disabled;
  final Color? backgroundColor;
  final Color? textColor;

  const StyledTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = true,
    this.disabled = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: backgroundColor ??
            (isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.errorContainer),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: disabled ? null : onPressed,
      child: AppText.styledBodyMedium(
        context,
        text,
        color: textColor ??
            (isPrimary
                ? Theme.of(context).colorScheme.surfaceBright
                : Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// A styled button that includes both an icon and text.
///
/// Similar to [StyledTextButton] but includes an icon alongside the text.
/// The icon can be positioned before or after the text.
class StyledTextIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Icon icon;
  final bool isPrimary;

  const StyledTextIconButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      icon: icon,
      label: AppText.styledBodyMedium(context, text,
          color: isPrimary
              ? Theme.of(context).colorScheme.surfaceBright
              : Theme.of(context).colorScheme.error),
    );
  }
}
