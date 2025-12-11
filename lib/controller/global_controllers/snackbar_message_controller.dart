import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/main.dart';
import 'package:traxx_wepapp/models/snack_bar_message.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Global controller for handling snackbar messages across the app.
class SnackbarMessageController extends GetxController {
  final message = Rxn<SnackBarMessage>();

  /// Clears the current message
  void clearMessage() {
    message.value = null;
  }

  /// Shows a success message
  void showSuccessMessage(String text) {
    // message.value = SnackBarMessage(
    //   message: text,
    //   type: SnackBarType.success,
    // );
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(

        content: AppText.styledBodyMedium(null, text,
            color: AppColors.white, weight: AppFontWeight.semiBold),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows an error message (styled the same as success but with error color)
  void showErrorMessage(String text) {
    // // keep the reactive message as well for any listeners
    // message.value = SnackBarMessage(
    //   message: text,
    //   type: SnackBarType.error,
    // );

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: AppText.styledBodyMedium(null, text,
            color: AppColors.white, weight: AppFontWeight.semiBold),
        backgroundColor: AppColors.inputError,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows an informational message (neutral color)
  void showInfoMessage(String text) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: AppText.styledBodyMedium(null, text,
            color: AppColors.white, weight: AppFontWeight.semiBold),
        backgroundColor: AppColors.primaryAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
