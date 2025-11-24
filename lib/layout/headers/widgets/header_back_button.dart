import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// A back button widget with optional text, responsive to screen size.
/// On desktop: shows icon + text. On tablet/phone: shows only icon.
class HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const HeaderBackButton({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenSize.isDesktop(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back,
            color: AppColors.primaryAccent,
            size: 24,
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            AppText.styledBodyLarge(
              context,
              text,
              color: AppColors.black,
            ),
          ],
        ],
      ),
    );
  }
}
