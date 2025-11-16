import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/email_verification_controller.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';

class EmailVerificationListeners extends StatelessWidget {
  final EmailVerificationController controller;
  final Widget child;

  const EmailVerificationListeners({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Watch for success messages
    ever(controller.successMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showSuccess(context, message);
          controller.clearSuccessMessage();
        });
      }
    });

    // Watch for error messages
    ever(controller.errorMessage, (String? message) {
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showError(context, message);
          controller.clearErrorMessage();
        });
      }
    });

    // Watch for navigation to host events
    ever(controller.shouldNavigateToHostEvents, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.hostOrganisationInfoForm, context);
          controller.clearNavigationFlags();
        });
      }
    });

    // Watch for navigation to login
    ever(controller.shouldNavigateToLogin, (bool shouldNavigate) {
      if (shouldNavigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pushAndRemoveAllRoute(AppRoute.welcome, context);
          controller.clearNavigationFlags();
        });
      }
    });

    return child;
  }
}
