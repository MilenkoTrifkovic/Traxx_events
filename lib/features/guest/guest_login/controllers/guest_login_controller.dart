import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';

/// Controller for guest login functionality
/// Handles business logic for guest authentication
class GuestLoginController extends GetxController {
  // Observable state
  final isLoading = false.obs;

  // Form validation flag
  final isFormValid = false.obs;

  // Format validation patterns
  // Invitation Code: 2 letters + 4 digits + 2 letters (case-insensitive)
  final invitationCodePattern = RegExp(r'^[a-zA-Z]{2}\d{4}[a-zA-Z]{2}$');
  
  // Batch ID: exactly 6 digits
  final batchIdPattern = RegExp(r'^\d{6}$');

  // Services
  final _firestoreServices = FirestoreServices();
  final _snackbarController = Get.find<SnackbarMessageController>();

  /// Handles the next button action
  /// Validates invitation code and batch ID, then navigates to RSVP page
  Future<void> handleNext({
    required String invitationCode,
    required String batchId,
  }) async {
    try {
      isLoading.value = true;

      // Validate invitation code and batch ID combination
      final result = await _firestoreServices.validateGuestLogin(
        invitationCode: invitationCode,
        batchId: batchId,
      );

      if (result == null) {
        _snackbarController.showErrorMessage(
          'Invalid invitation code or batch ID. Please check your details.',
        );
        return;
      }

      // Extract event and guest from result
      // Note: Service layer already validated that guest.eventId matches event.eventId
      final event = result['event'] as Event;
      final guest = result['guest'] as GuestModel;

      // Success - show confirmation message
      _snackbarController.showSuccessMessage(
        'Login successful! Guest ${guest.name} authenticated for event ${event.name}.',
      );

      // TODO: Navigate to RSVP page
      // pushRoute(AppRoute.guestResponse, context, queryParams: {
      //   'invitationId': guest.docId,
      //   'eventId': event.eventId,
      // });
      
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
    final codeValid = invitationCodePattern.hasMatch(invitationCode.trim());
    final batchValid = batchIdPattern.hasMatch(batchId.trim());
    
    isFormValid.value = codeValid && batchValid;
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}