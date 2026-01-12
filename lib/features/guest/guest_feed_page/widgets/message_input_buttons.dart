import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Attach file button widget for message input
class AttachButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPhone;

  const AttachButton({
    super.key,
    required this.onPressed,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final size = isPhone ? 40.0 : 44.0;
    final iconSize = isPhone ? 20.0 : 24.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onPressed != null
            ? AppColors.surfaceCard
            : AppColors.surfaceCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.attach_file,
          size: iconSize,
          color:
              onPressed != null ? AppColors.primaryAccent : AppColors.textMuted,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Send message button widget
class SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPhone;

  const SendButton({
    super.key,
    required this.onPressed,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final size = isPhone ? 40.0 : 44.0;
    final iconSize = isPhone ? 20.0 : 24.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            onPressed != null ? AppColors.primaryAccent : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
        border: Border.all(
          color: onPressed != null
              ? AppColors.primaryAccent
              : AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.send,
          size: iconSize,
          color: onPressed != null ? AppColors.white : AppColors.textMuted,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
