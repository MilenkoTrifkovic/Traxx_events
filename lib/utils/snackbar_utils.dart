import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Utility class for showing styled snackbar messages throughout the app.
/// Provides consistent styling and behavior for different types of notifications.
///
/// Usage:
/// ```dart
/// // Show success message
/// SnackBarUtils.showSuccess(context, 'Operation completed successfully');
///
/// // Show error message
/// SnackBarUtils.showError(context, 'Something went wrong');
/// ```
class SnackBarUtils {
  /// Shows a success message.
  ///
  /// [context] The build context
  /// [message] The message to display
  /// [duration] How long to show the message (defaults to 3 seconds)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.styledBodyMedium(
          context,
          message,
          color: AppColors.onPrimary(context),
        ),
        backgroundColor: AppColors.primaryOld(context),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows an error message.
  ///
  /// [context] The build context
  /// [message] The error message to display
  /// [duration] How long to show the message (defaults to 4 seconds)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.styledBodyMedium(
          context,
          message,
          color: AppColors.onError(context),
        ),
        backgroundColor: AppColors.error(context),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows a info message.
  ///
  /// [context] The build context
  /// [message] The message to display
  /// [duration] How long to show the message (defaults to 3 seconds)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.styledBodyMedium(
          context,
          message,
          color: AppColors.onSecondary(context),
        ),
        backgroundColor: AppColors.secondaryOld(context),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
