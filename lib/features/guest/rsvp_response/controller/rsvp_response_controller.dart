import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/invitation_status.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/firestore_services/invitation_response_services.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

/// Validation result for email uniqueness checks
class EmailValidationResult {
  final String errorMessage;
  final int duplicateIndex;

  EmailValidationResult({
    required this.errorMessage,
    required this.duplicateIndex,
  });
}

class RsvpResponseController extends GetxController {
  final InvitationResponseServices _invitationService =
      InvitationResponseServices();
  final FirestoreServices _firestoreService = FirestoreServices();
  final SnackbarMessageController _snackbarController =
      Get.find<SnackbarMessageController>();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
  /// [isInvitingCompanionsByEmail] is only used when count > 0
  Future<bool> submitCompanions(
    int count, {
    bool? isInvitingCompanionsByEmail,
  }) async {
    if (isSubmitting.value) return false;

    // Validate count is within allowed range
    if (count < 0 || count > maxGuestInvite) {
      error.value = 'Invalid companion count. Please select a valid number.';
      return false;
    }

    // Validate isInvitingCompanionsByEmail is provided when count > 0
    if (count > 0 && isInvitingCompanionsByEmail == null) {
      error.value = 'Please specify how you want to handle companion information.';
      return false;
    }

    try {
      isSubmitting.value = true;
      error.value = null;

      await _invitationService.submitCompanions(
        invitationId: invitationId!,
        companionsCount: count,
        isInvitingCompanionsByEmail: isInvitingCompanionsByEmail,
      );

      // Update local state by creating a new status model
      if (invitationStatus.value != null) {
        invitationStatus.value = invitationStatus.value!.copyWith(
          companionsCount: count,
          companionsSubmittedAt: DateTime.now(),
          isInvitingCompanionsByEmail: isInvitingCompanionsByEmail,
        );
      }

      print('✅ Companion count submitted: $count, isInvitingCompanionsByEmail: $isInvitingCompanionsByEmail');
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

    // Email validation is now handled by validateCompanionEmail method
    // This method is called from validateAndCreateCompanion which handles validation
    // We still check here as a safety net, but validation should happen before calling this

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

  // ============================================================================
  // Email Validation Methods (Business Logic)
  // ============================================================================

  /// Validates that a companion email is unique
  /// Checks against: primary guest email, saved companions, and other pending emails
  /// Returns error message if validation fails, null if valid
  String? validateCompanionEmail(
    String email, {
    List<String>? otherPendingEmails,
  }) {
    final trimmedEmail = email.trim().toLowerCase();

    // Check against primary guest email
    final primaryGuestEmail = invitationStatus.value?.guestEmail;
    if (primaryGuestEmail != null &&
        trimmedEmail == primaryGuestEmail.trim().toLowerCase()) {
      return 'Companion email cannot be the same as your email address';
    }

    // Check against saved companions
    final existingCompanions = invitationStatus.value?.companions ?? [];
    final duplicateInSaved = existingCompanions.any((companion) {
      final companionEmail =
          (companion['guestEmail'] as String?)?.trim().toLowerCase();
      return companionEmail == trimmedEmail;
    });

    if (duplicateInSaved) {
      return 'A companion with this email already exists';
    }

    // Check against other pending emails (if provided)
    if (otherPendingEmails != null) {
      final duplicateInPending = otherPendingEmails.any((otherEmail) {
        return otherEmail.trim().toLowerCase() == trimmedEmail;
      });

      if (duplicateInPending) {
        return 'This email is already used for another companion. Please use a different email address.';
      }
    }

    return null; // Valid
  }

  /// Validates that all companion emails in a list are unique
  /// Returns validation result with error message and index of first duplicate
  /// Returns null if all emails are valid
  EmailValidationResult? validateAllCompanionEmails(
    List<String> emails,
  ) {
    final emailSet = <String>{};

    for (int i = 0; i < emails.length; i++) {
      final email = emails[i].trim().toLowerCase();
      if (email.isEmpty) continue; // Skip empty emails (will be caught by form validation)

      // Validate individual email
      final individualError = validateCompanionEmail(email);
      if (individualError != null) {
        return EmailValidationResult(
          errorMessage: 'Companion ${i + 1}: $individualError',
          duplicateIndex: i,
        );
      }

      // Check for duplicates within the list
      if (emailSet.contains(email)) {
        return EmailValidationResult(
          errorMessage:
              'Duplicate email addresses found. Each companion must have a unique email address.',
          duplicateIndex: i,
        );
      }

      emailSet.add(email);
    }

    return null; // All valid
  }

  /// Validates and creates a companion guest with proper error handling and snackbar messages
  /// Returns guestId on success, null on failure
  /// Shows snackbar messages for validation errors
  Future<String?> validateAndCreateCompanion({
    required String name,
    required String email,
    String? address,
    String? city,
    String? state,
    String? country,
    Gender? gender,
    List<String>? otherPendingEmails,
  }) async {
    // Validate email uniqueness
    final emailError = validateCompanionEmail(email, otherPendingEmails: otherPendingEmails);
    if (emailError != null) {
      _snackbarController.showErrorMessage(emailError);
      error.value = emailError;
      return null;
    }

    // Create companion (this will also validate and show errors)
    final guestId = await createAndInviteGuest(
      name: name,
      email: email,
      address: address,
      city: city,
      state: state,
      country: country,
      gender: gender,
    );

    if (guestId == null) {
      // Show snackbar for error (error.value is already set in createAndInviteGuest)
      _snackbarController.showErrorMessage(
        error.value ?? 'Failed to add companion. Please try again.',
      );
    }

    return guestId;
  }

  // ============================================================================
  // Send Email Invitations for Companions (Business Logic)
  // ============================================================================

  /// Sends email invitations to companions via Cloud Function
  /// This is used when isInvitingCompanionsByEmail = true
  /// First creates guest documents, then sends invitations with guestId
  /// Returns true if all invitations were sent successfully, false otherwise
  Future<bool> sendCompanionInvitations({
    required List<Map<String, dynamic>> companionData, // List of {name, email, address, city, state, country, gender}
  }) async {
    if (invitationId == null || invitationId!.isEmpty) {
      error.value = 'Invitation ID is not available';
      debugPrint('❌ sendCompanionInvitations: invitationId is null or empty');
      return false;
    }

    final status = invitationStatus.value;
    if (status == null) {
      error.value = 'Invitation status not available';
      debugPrint('❌ sendCompanionInvitations: invitationStatus is null');
      return false;
    }

    if (status.eventId.isEmpty || status.organisationId.isEmpty) {
      error.value = 'Event or organisation information is missing';
      debugPrint('❌ sendCompanionInvitations: eventId or organisationId is empty');
      return false;
    }

    if (companionData.isEmpty) {
      error.value = 'No companion data provided';
      debugPrint('❌ sendCompanionInvitations: companionData is empty');
      return false;
    }

    try {
      isSubmitting.value = true;
      error.value = null;

      // Step 1: Create guest documents with groupId atomically
      // This includes updating main guest and creating all companions in one batch
      debugPrint('📝 Creating ${companionData.length} companion guest document(s) with groupId...');
      
      // Prepare companion GuestModel instances
      final List<GuestModel> companionGuests = [];
      for (final companion in companionData) {
        final email = (companion['email'] as String?)?.trim() ?? '';
        final name = (companion['name'] as String?)?.trim() ?? '';
        
        if (email.isEmpty) {
          debugPrint('⚠️ Skipping companion with empty email: $name');
          continue;
        }

        // Create GuestModel (without guestId yet - will be assigned in batch)
        final guest = GuestModel(
          name: name,
          email: email,
          eventId: status.eventId,
          address: companion['address'] as String?,
          city: companion['city'] as String?,
          country: companion['country'] as String?,
          state: companion['state'] as String?,
          gender: companion['gender'] as Gender?,
          isDisabled: false,
          isInvited: false, // Will be updated after email is sent
          maxGuestInvite: companion['maxGuestInvite'] ?? 0,
        );
        companionGuests.add(guest);
      }

      if (companionGuests.isEmpty) {
        error.value = 'No valid companion data provided';
        debugPrint('❌ sendCompanionInvitations: No valid companions');
        return false;
      }

      // Get main guest ID from invitation status
      final mainGuestId = status.guestId;
      if (mainGuestId.isEmpty) {
        error.value = 'Main guest ID not found in invitation';
        debugPrint('❌ sendCompanionInvitations: mainGuestId is empty');
        return false;
      }

      // Create companions with groupId atomically (updates main guest + creates companions)
      final groupResult = await _firestoreService.createCompanionsWithGroupId(
        mainGuestId: mainGuestId,
        companions: companionGuests,
      );

      final groupId = groupResult['groupId'] as String;
      final createdGuestIds = groupResult['createdGuestIds'] as List<String>;
      
      debugPrint('✅ Created ${createdGuestIds.length} companion(s) with groupId=$groupId');

      // Step 2: Fetch created guests to get their batchId
      final List<GuestModel> createdGuests = [];
      for (final guestId in createdGuestIds) {
        final guestDoc = await FirebaseFirestore.instance
            .collection('guests')
            .doc(guestId)
            .get();
        if (guestDoc.exists) {
          createdGuests.add(GuestModel.fromFirestore(guestDoc.data()!, guestDoc.id));
        }
      }

      // Step 3: Prepare invitations array for Cloud Function
      final List<Map<String, dynamic>> invitations = [];
      for (final guest in createdGuests) {
        final invitation = {
          'guestEmail': guest.email,
          'guestName': guest.name,
          'guestId': guest.guestId,
          'maxGuestInvite': guest.maxGuestInvite,
        };
        
        // Include batchId if available
        if (guest.batchId != null && guest.batchId!.trim().isNotEmpty) {
          invitation['batchId'] = guest.batchId;
        }
        
        invitations.add(invitation);
      }

      if (invitations.isEmpty) {
        error.value = 'No valid email addresses found for companions';
        debugPrint('❌ sendCompanionInvitations: No valid emails');
        return false;
      }

      debugPrint('📧 Sending ${invitations.length} companion invitation(s)...');

      // Step 3: Get invitation code directly from event document
      String? invitationCode;
      try {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(status.eventId)
            .get();
        
        if (eventDoc.exists) {
          invitationCode = eventDoc.data()?['invitationCode'] as String?;
          debugPrint('📋 Fetched invitation code from event: $invitationCode');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch invitation code from event: $e');
        // Continue without invitation code - it's optional
      }

      // Step 4: Call Cloud Function to send invitations
      final callable = _functions.httpsCallable('sendInvitations');

      final cloudFunctionResult = await callable.call(<String, dynamic>{
        'eventId': status.eventId,
        'organisationId': status.organisationId,
        'invitations': invitations,
        'demographicQuestionSetId': status.demographicQuestionSetId,
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode,
      });

      final data = cloudFunctionResult.data as Map<String, dynamic>?;
      if (data == null) {
        error.value = 'Failed to send invitations. Please try again.';
        debugPrint('❌ sendCompanionInvitations: Cloud function returned null');
        return false;
      }

      final invited = (data['invited'] as int?) ?? 0;
      final results = (data['results'] as List?) ?? [];

      // Step 3: Update isInvited flag for successfully sent invitations
      final sentEmails = results
          .where((r) => r is Map && r['status'] == 'sent')
          .map((r) => (r['guestEmail'] ?? '').toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (sentEmails.isNotEmpty) {
        // Collect guest IDs for successfully sent invitations
        final List<String> invitedGuestIds = [];
        for (int i = 0; i < invitations.length; i++) {
          final invitationEmail = (invitations[i]['guestEmail'] as String).trim().toLowerCase();
          if (sentEmails.contains(invitationEmail) && i < createdGuestIds.length) {
            invitedGuestIds.add(createdGuestIds[i]);
          }
        }

        // Update isInvited flag via service layer
        if (invitedGuestIds.isNotEmpty) {
          await _firestoreService.updateGuestsInvitedStatus(invitedGuestIds);
        }
      }

      debugPrint('✅ Companion invitations sent: $invited of ${invitations.length}');

      if (invited == invitations.length) {
        _snackbarController.showSuccessMessage(
          'All companion invitations sent successfully!',
        );
        return true;
      } else if (invited > 0) {
        // Some succeeded, some failed
        final failed = results
            .where((r) => r is Map && r['status'] == 'failed')
            .map((r) => (r['guestEmail'] ?? 'Unknown').toString())
            .join(', ');
        _snackbarController.showInfoMessage(
          '$invited of ${invitations.length} invitations sent. Failed: $failed',
        );
        return false;
      } else {
        // All failed
        error.value = 'Failed to send companion invitations. Please try again.';
        _snackbarController.showErrorMessage(
          'Failed to send companion invitations. Please try again.',
        );
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      error.value = 'Failed to send invitations: ${e.message ?? 'Unknown error'}';
      debugPrint('❌ sendCompanionInvitations FirebaseFunctionsException: $e');
      _snackbarController.showErrorMessage(
        'Failed to send invitations: ${e.message ?? 'Unknown error'}',
      );
      return false;
    } catch (e, st) {
      error.value = 'Failed to send companion invitations. Please try again.';
      debugPrint('❌ sendCompanionInvitations error: $e\n$st');
      _snackbarController.showErrorMessage(
        'Failed to send companion invitations. Please try again.',
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Gets the count of existing companions for the current invitation
  /// Used when isInvitingCompanionsByEmail = true to check how many companions already exist
  /// Returns the number of existing companions, or null if unable to determine
  Future<int?> getExistingCompanionCount() async {
    final status = invitationStatus.value;
    if (status == null) return null;

    final mainGuestId = status.guestId;
    if (mainGuestId.isEmpty) return null;

    try {
      // Get groupId for main guest via service layer
      final groupId = await _firestoreService.getGroupIdForMainGuest(mainGuestId);
      
      if (groupId == null || groupId.isEmpty) {
        return null;
      }

      // Get companion count by groupId via service layer
      final existingCompanionsCount = await _firestoreService.getCompanionCountByGroupId(groupId);
      return existingCompanionsCount;
    } catch (e) {
      debugPrint('⚠️ Error getting existing companion count: $e');
      return null;
    }
  }

  /// Gets the latest invitation data from Firestore
  /// Used for navigation flow state determination
  /// Returns the invitation data map, or null if not found
  Future<Map<String, dynamic>?> getLatestInvitationData() async {
    if (invitationId == null || invitationId!.isEmpty) {
      return null;
    }

    try {
      return await _firestoreService.getInvitationById(invitationId!);
    } catch (e) {
      debugPrint('⚠️ Error getting latest invitation data: $e');
      return null;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
