import 'package:get/get.dart';
import 'package:traxx_wepapp/models/invitation_status.dart';
import 'package:traxx_wepapp/services/firestore_services/invitation_response_services.dart';

class RsvpResponseController extends GetxController {
  final InvitationResponseServices _invitationService =
      InvitationResponseServices();

  final RxBool isLoading = true.obs; // Start with true to load initial state
  final RxBool isSubmitting = false.obs;
  final Rx<String?> error = Rx<String?>(null);

  // RSVP status - now using the typed model
  final Rx<InvitationStatus?> invitationStatus = Rx<InvitationStatus?>(null);

  String? invitationId;
  String? token;
  String? eventName;

  // Convenience getters for UI
  bool get hasResponded => invitationStatus.value?.hasResponded ?? false;
  bool? get isAttending => invitationStatus.value?.isAttending;
  DateTime? get rsvpSubmittedAt => invitationStatus.value?.rsvpSubmittedAt;
  String? get declineReason => invitationStatus.value?.declineReason;
  String? get guestName => invitationStatus.value?.guestName;
  String? get eventId => invitationStatus.value?.eventId; // For fetching event data
  
  // Step completion getters
  bool get hasDemographics => invitationStatus.value?.hasDemographics ?? false;
  bool get hasMenuSelection => invitationStatus.value?.hasMenuSelection ?? false;
  bool get requiresDemographics => invitationStatus.value?.requiresDemographics ?? false;
  bool get isFullyCompleted => invitationStatus.value?.isFullyCompleted ?? false;
  String? get nextIncompleteStep => invitationStatus.value?.nextIncompleteStep;

  @override
  void onInit() {
    super.onInit();
    // Note: checkExistingResponse() is called manually from the page
    // after invitationId, token, and eventName are assigned
    print('🔄 RsvpResponseController initialized');
  }

  /// Check if user has already responded to RSVP
  Future<void> checkExistingResponse() async {
    if (invitationId == null || invitationId!.isEmpty) {
      error.value = 'Invalid invitation ID';
      isLoading.value = false;
      return;
    }

    // Token validation - ensure URL hasn't been tampered with
    if (token == null || token!.isEmpty) {
      error.value = 'Invalid invitation link. Please use the link from your email.';
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;

      // Fetch invitation status from Firestore
      final status = await _invitationService.checkRsvpStatus(
        invitationId: invitationId!,
      );

      if (status == null) {
        error.value = 'Invitation not found';
        isLoading.value = false;
        return;
      }

      // Validate token matches the one from Firestore (local check)
      if (!_validateToken(status)) {
        error.value = 'Invalid or expired invitation link. Please check your email for the correct link.';
        isLoading.value = false;
        return;
      }

      // Check if invitation has expired
      if (_isExpired(status)) {
        error.value = 'This invitation has expired. Please contact the event organizer for assistance.';
        isLoading.value = false;
        return;
      }

      // Update state with the typed model
      invitationStatus.value = status;
      
      print('✅ Invitation loaded: ${status.statusMessage}');
    } catch (e) {
      error.value = 'Failed to load invitation. Please try again.';
      print('❌ Error checking RSVP status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Private method to validate token matches the invitation
  /// Compares the token from URL with the token stored in Firestore
  bool _validateToken(InvitationStatus status) {
    // Token must match exactly
    return status.token == token;
  }

  /// Private method to check if invitation has expired
  /// Compares current time with expiresAt timestamp
  bool _isExpired(InvitationStatus status) {
    if (status.expiresAt == null) {
      return false; // No expiration set, invitation is valid
    }
    
    // Check if current time is after expiration time
    return DateTime.now().isAfter(status.expiresAt!);
  }

  /// Called when user clicks "Yes, I'm attending"
  /// Returns true if submission was successful, false otherwise
  Future<bool> submitAttending() async {
    if (isSubmitting.value) return false;

    try {
      isSubmitting.value = true;
      error.value = null;

      await _invitationService.submitRsvp(
        invitationId: invitationId!,
        isAttending: true,
      );

      // Update local state by creating a new status model
      if (invitationStatus.value != null) {
        invitationStatus.value = invitationStatus.value!.copyWith(
          hasResponded: true,
          isAttending: true,
          rsvpSubmittedAt: DateTime.now(),
        );
      }

      print('✅ User is attending - RSVP submitted successfully');
      return true;
    } catch (e) {
      error.value = 'Failed to submit response. Please try again.';
      print('❌ Error submitting RSVP (attending): $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Called when user clicks "No, I can't make it"
  /// Returns true if submission was successful, false otherwise
  Future<bool> submitNotAttending({String? declineReason}) async {
    if (isSubmitting.value) return false;

    try {
      isSubmitting.value = true;
      error.value = null;

      await _invitationService.submitRsvp(
        invitationId: invitationId!,
        isAttending: false,
        declineReason: declineReason,
      );

      // Update local state by creating a new status model
      if (invitationStatus.value != null) {
        invitationStatus.value = invitationStatus.value!.copyWith(
          hasResponded: true,
          isAttending: false,
          rsvpSubmittedAt: DateTime.now(),
          declineReason: declineReason,
        );
      }

      print('❌ User declined - RSVP submitted successfully');
      return true;
    } catch (e) {
      error.value = 'Failed to submit response. Please try again.';
      print('❌ Error submitting RSVP (not attending): $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearError() {
    error.value = null;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
