import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/invitation_status.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/firestore_services/invitation_response_services.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

class RsvpResponseController extends GetxController {
  final InvitationResponseServices _invitationService =
      InvitationResponseServices();
  final FirestoreServices _firestoreService = FirestoreServices();

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
  int get maxGuestInvite => invitationStatus.value?.maxGuestInvite ?? 0;
  int? get companionsCount => invitationStatus.value?.companionsCount;
  int get savedCompanionsCount => invitationStatus.value?.savedCompanionsCount ?? 0;
  int get remainingCompanionsToCreate => invitationStatus.value?.remainingCompanionsToCreate ?? 0;
  
  // Step completion getters
  bool get hasDemographics => invitationStatus.value?.hasDemographics ?? false;
  bool get canInviteCompanions => invitationStatus.value?.canInviteCompanions ?? false;
  bool get hasSubmittedCompanionCount => invitationStatus.value?.hasSubmittedCompanionCount ?? false;
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

  /// Called when user submits their companion count selection
  /// Returns true if submission was successful, false otherwise
  Future<bool> submitCompanions(int count) async {
    if (isSubmitting.value) return false;

    // Validate count is within allowed range
    if (count < 0 || count > maxGuestInvite) {
      error.value = 'Invalid companion count. Please select a valid number.';
      return false;
    }

    try {
      isSubmitting.value = true;
      error.value = null;

      await _invitationService.submitCompanions(
        invitationId: invitationId!,
        companionsCount: count,
      );

      // Update local state by creating a new status model
      if (invitationStatus.value != null) {
        invitationStatus.value = invitationStatus.value!.copyWith(
          companionsCount: count,
          companionsSubmittedAt: DateTime.now(),
        );
      }

      print('✅ Companion count submitted: $count');
      return true;
    } catch (e) {
      error.value = 'Failed to submit companion count. Please try again.';
      print('❌ Error submitting companion count: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ---------------------------
  // Companion Guest Management
  // ---------------------------

  /// Creates a companion guest and links them to the invitation atomically
  /// 
  /// This is a convenience method that delegates to FirestoreServices to perform
  /// an atomic batch operation that:
  /// 1. Creates a new guest document in the 'guests' collection
  /// 2. Adds the companion entry to the invitation's 'companions' array
  /// 
  /// Both operations succeed together or fail together, ensuring data consistency.
  /// 
  /// Parameters:
  /// - [name]: Guest's full name (required)
  /// - [email]: Guest's email address (required)
  /// - [address]: Guest's address (optional)
  /// - [city]: Guest's city (optional)
  /// - [state]: Guest's state (optional)
  /// - [country]: Guest's country (optional)
  /// - [gender]: Guest's gender (optional)
  /// 
  /// Returns the created guestId on success, null on failure
  Future<String?> createAndInviteGuest({
    required String name,
    required String email,
    String? address,
    String? city,
    String? state,
    String? country,
    Gender? gender,
  }) async {
    if (invitationId == null || invitationId!.isEmpty) {
      error.value = 'Invitation ID is not available';
      debugPrint('❌ createAndInviteGuest: invitationId is null or empty');
      return null;
    }

    if (eventId == null || eventId!.isEmpty) {
      error.value = 'Event ID is not available';
      debugPrint('❌ createAndInviteGuest: eventId is null or empty');
      return null;
    }

    // Validate required fields
    if (name.trim().isEmpty || email.trim().isEmpty) {
      error.value = 'Name and email are required';
      debugPrint('❌ createAndInviteGuest: name or email is empty');
      return null;
    }

    try {
      // Create GuestModel instance
      final guestModel = GuestModel(
        name: name.trim(),
        email: email.trim(),
        eventId: eventId!,
        maxGuestInvite: 0, // Companions can't invite others
        address: address?.trim(),
        city: city?.trim(),
        state: state?.trim(),
        country: country?.trim(),
        gender: gender,
        isDisabled: false,
        isInvited: false,
      );

      // Call service layer to perform atomic operation
      final guestId = await _firestoreService.createCompanionAndLinkToInvitation(
        invitationId: invitationId!,
        guest: guestModel,
      );

      debugPrint('✅ createAndInviteGuest: companion created successfully, guestId=$guestId');
      return guestId;
    } catch (e, st) {
      // Parse error message for better user feedback
      if (e.toString().contains('already exists')) {
        error.value = 'A companion with this email already exists';
      } else if (e.toString().contains('not found')) {
        error.value = 'Invitation not found';
      } else {
        error.value = 'Failed to add companion. Please try again.';
      }
      debugPrint('❌ createAndInviteGuest error: $e\n$st');
      return null;
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
