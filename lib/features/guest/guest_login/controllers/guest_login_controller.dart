import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// Controller for guest login functionality
/// Handles UI logic for guest authentication
class GuestLoginController extends GetxController {
  // Observable state
  final isLoading = false.obs;

  // Form validation flag
  final isFormValid = false.obs;

  // Format validation patterns
  // Invitation Code: 2 letters + 4 digits + 2 letters (case-insensitive)
  final invitationCodePattern = RegExp(r'^[A-Z0-9]{8}$');

  // Batch ID: exactly 6 digits
  final batchIdPattern = RegExp(r'^\d{6}$');

  // Controllers
  final _guestSessionController = Get.find<GuestSessionController>();
  final _snackbarController = Get.find<SnackbarMessageController>();

  /// Handles the next button action
  /// Validates invitation code and batch ID, then navigates to appropriate page
  Future<void> handleNext({
    required String invitationCode,
    required String batchId,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;

      // Authenticate through global session controller
      final success = await _guestSessionController.authenticate(
        invitationCode: invitationCode,
        batchId: batchId,
      );

      if (!success) {
        _snackbarController.showErrorMessage(
          'Invalid invitation code or batch ID. Please check your details.',
        );
        return;
      }

      // Success - get guest and event from session controller
      final guest = _guestSessionController.guest.value!;

      _snackbarController.showSuccessMessage(
        'Login successful! Welcome ${guest.name}.',
      );

      // Navigate to guest responses preview page
      // context.push(AppRoute.guestResponsesPreview.path);
      pushAndRemoveAllRoute(AppRoute.guestResponsesPreview, context);
    } catch (e) {
      _snackbarController.showErrorMessage(
        'An error occurred during login. Please try again.',
      );
      print('❌ Guest login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Validates the form fields based on format patterns
  void validateForm(String invitationCode, String batchId) {
    final code = invitationCode.trim().toUpperCase();
    final batch = batchId.trim();

    final codeValid = invitationCodePattern.hasMatch(code);
    final batchValid = batchIdPattern.hasMatch(batch);

    isFormValid.value = codeValid && batchValid;
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
