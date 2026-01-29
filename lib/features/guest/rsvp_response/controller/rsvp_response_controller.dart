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

  final RxBool isLoading = false.obs; // Start with true to load initial state
  final RxBool isSubmitting = false.obs;
  final Rx<String?> error = Rx<String?>(null);

  final RxnString invitationCode = RxnString();
  final RxnString batchId = RxnString();

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
  String? get eventId =>
      invitationStatus.value?.eventId; // For fetching event data
  int get maxGuestInvite => invitationStatus.value?.maxGuestInvite ?? 0;
  int? get companionsCount => invitationStatus.value?.companionsCount;
  int get savedCompanionsCount =>
      invitationStatus.value?.savedCompanionsCount ?? 0;
  int get remainingCompanionsToCreate =>
      invitationStatus.value?.remainingCompanionsToCreate ?? 0;

  // Step completion getters
  bool get hasDemographics => invitationStatus.value?.hasDemographics ?? false;
  bool get canInviteCompanions =>
      invitationStatus.value?.canInviteCompanions ?? false;
  bool get hasSubmittedCompanionCount =>
      invitationStatus.value?.hasSubmittedCompanionCount ?? false;
  bool get hasMenuSelection =>
      invitationStatus.value?.hasMenuSelection ?? false;
  bool get requiresDemographics =>
      invitationStatus.value?.requiresDemographics ?? false;
  bool get isFullyCompleted =>
      invitationStatus.value?.isFullyCompleted ?? false;
  String? get nextIncompleteStep => invitationStatus.value?.nextIncompleteStep;
  bool get isInvitingByEmail =>
      invitationStatus.value?.isInvitingCompanionsByEmail == true;

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
      error.value =
          'Invalid invitation link. Please use the link from your email.';
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
        error.value =
            'Invalid or expired invitation link. Please check your email for the correct link.';
        isLoading.value = false;
        return;
      }

      // Check if invitation has expired
      if (_isExpired(status)) {
        error.value =
            'This invitation has expired. Please contact the event organizer for assistance.';
        isLoading.value = false;
        return;
      }

      // Update state with the typed model
      invitationStatus.value = status;

      // Pull extra fields from invitations/{invitationId}
      final inv = await _firestoreService.getInvitationById(invitationId!);
      if (inv != null) {
        final code = (inv['invitationCode'] ?? '').toString().trim();
        final bId = (inv['batchId'] ?? '').toString().trim();

        invitationCode.value = code.isEmpty ? null : code;
        batchId.value = bId.isEmpty ? null : bId;
      }

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
      error.value =
          'Please specify how you want to handle companion information.';
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

      print(
          '✅ Companion count submitted: $count, isInvitingCompanionsByEmail: $isInvitingCompanionsByEmail');
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
    bool? isAttending,
  }) async {
    if (invitationId == null || invitationId!.isEmpty) {
      error.value = 'Invitation ID is not available';
      return null;
    }
    if (token == null || token!.isEmpty) {
      error.value = 'Invalid invitation link';
      return null;
    }

    if (name.trim().isEmpty || email.trim().isEmpty) {
      error.value = 'Name and email are required';
      return null;
    }

    try {
      final callable = _functions.httpsCallable('addCompanionToInvitation');

      final res = await callable.call({
        'invitationId': invitationId!,
        'token': token!,
        'companion': {
          'name': name.trim(),
          'email': email.trim(),
          'address': address?.trim(),
          'city': city?.trim(),
          'state': state?.trim(),
          'country': country?.trim(),
          'gender': gender?.name, // store as string
          'isAttending': isAttending,
        }
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final guestId = (data['guestId'] ?? '').toString().trim();
      if (guestId.isEmpty) {
        error.value = 'Failed to add companion. Please try again.';
        return null;
      }

      // ✅ refresh invitation status so saved/remaining counters update in UI
      await checkExistingResponse();

      return guestId;
    } on FirebaseFunctionsException catch (e) {
      error.value = e.message ?? 'Failed to add companion. Please try again.';
      return null;
    } catch (e) {
      error.value = 'Failed to add companion. Please try again.';
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

    // ✅ Proxy mode: allow duplicates (and even empty)
    if (!isInvitingByEmail) return null;

    // Email-invite mode: enforce uniqueness
    final existingCompanions = invitationStatus.value?.companions ?? [];
    final duplicateInSaved = existingCompanions.any((companion) {
      final companionEmail =
          (companion['guestEmailLower'] as String?)?.trim().toLowerCase() ??
              (companion['guestEmail'] as String?)?.trim().toLowerCase();
      return companionEmail == trimmedEmail;
    });

    if (duplicateInSaved) {
      return 'A companion with this email already exists';
    }

    if (otherPendingEmails != null) {
      final duplicateInPending = otherPendingEmails.any(
        (e) => e.trim().toLowerCase() == trimmedEmail,
      );
      if (duplicateInPending) {
        return 'This email is already used for another companion. Please use a different email address.';
      }
    }

    return null;
  }

  /// Validates that all companion emails in a list are unique
  /// Returns validation result with error message and index of first duplicate
  /// Returns null if all emails are valid
  EmailValidationResult? validateAllCompanionEmails(List<String> emails) {
    // ✅ Proxy mode: allow duplicates
    if (!isInvitingByEmail) return null;

    final emailSet = <String>{};

    for (int i = 0; i < emails.length; i++) {
      final email = emails[i].trim().toLowerCase();
      if (email.isEmpty) continue;

      final individualError = validateCompanionEmail(email);
      if (individualError != null) {
        return EmailValidationResult(
          errorMessage: 'Companion ${i + 1}: $individualError',
          duplicateIndex: i,
        );
      }

      if (emailSet.contains(email)) {
        return EmailValidationResult(
          errorMessage:
              'Duplicate email addresses found. Each companion must have a unique email address.',
          duplicateIndex: i,
        );
      }

      emailSet.add(email);
    }

    return null;
  }

  /// Validates and creates a companion guest with proper error handling and snackbar messages
  /// Returns guestId on success, null on failure
  /// Shows snackbar messages for validation errors
  Future<String?> validateAndCreateCompanion({
    required String name,
    required String email,
    bool? isAttending,
    String? address,
    String? city,
    String? state,
    String? country,
    Gender? gender,
    List<String>? otherPendingEmails,
  }) async {
    // Validate email uniqueness
    final emailError =
        validateCompanionEmail(email, otherPendingEmails: otherPendingEmails);
    if (emailError != null) {
      _snackbarController.showErrorMessage(emailError);
      error.value = emailError;
      return null;
    }

    // Create companion (this will also validate and show errors)
    final guestId = await createAndInviteGuest(
      name: name,
      email: email,
      isAttending: isAttending,
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
    required List<Map<String, dynamic>> companionData,
  }) async {
    if (invitationId == null || invitationId!.isEmpty) {
      error.value = 'Invitation ID is not available';
      return false;
    }
    if (token == null || token!.isEmpty) {
      error.value = 'Invalid invitation link';
      return false;
    }

    final status = invitationStatus.value;
    if (status == null) {
      error.value = 'Invitation status not available';
      return false;
    }

    if (companionData.isEmpty) {
      error.value = 'No companion data provided';
      return false;
    }

    try {
      isSubmitting.value = true;
      error.value = null;

      // ✅ 1) Create companion guest docs + link to invitation (SERVER SIDE)
      final addCompanion = _functions.httpsCallable('addCompanionToInvitation');

      final List<Map<String, dynamic>> invitations = [];

      for (final c in companionData) {
        final name = (c['name'] ?? '').toString().trim();
        final email = (c['email'] ?? '').toString().trim();

        if (name.isEmpty || email.isEmpty) continue;

        final res = await addCompanion.call({
          'invitationId': invitationId!,
          'token': token!,
          'companion': {
            'name': name,
            'email': email,
            'address': (c['address'] as String?)?.trim(),
            'city': (c['city'] as String?)?.trim(),
            'state': (c['state'] as String?)?.trim(),
            'country': (c['country'] as String?)?.trim(),
            'gender': (c['gender'] is Gender)
                ? (c['gender'] as Gender).name
                : c['gender'],
            'isAttending': c['isAttending'],
          },
        });

        final data = Map<String, dynamic>.from(res.data as Map);
        final createdGuestId = (data['guestId'] ?? '').toString().trim();
        final createdBatchId = (data['batchId'] ?? '').toString().trim();
        if (createdGuestId.isEmpty) continue;

        // ✅ Build sendInvitations payload from form data (NO /guests reads)
        invitations.add({
          'guestEmail': email,
          'guestId': createdGuestId,
          'guestName': name,
          'maxGuestInvite': 0, // companions can't invite others
          if (createdBatchId.isNotEmpty) 'batchId': createdBatchId,
        });
      }

      if (invitations.isEmpty) {
        error.value = 'No valid companion invitations to send';
        _snackbarController.showErrorMessage(error.value!);
        return false;
      }

      // ✅ 2) Fetch event invitationCode (event read is public in your rules)
      String? invitationCode;
      try {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(status.eventId)
            .get();
        if (eventDoc.exists) {
          invitationCode = eventDoc.data()?['invitationCode'] as String?;
        }
      } catch (_) {
        // optional
      }

      // ✅ 3) Send emails (Cloud Function also updates guests.isInvited server-side)
      final sendInvites = _functions.httpsCallable('sendInvitations');

      final cfRes = await sendInvites.call({
        'eventId': status.eventId,
        'organisationId': status.organisationId,
        'demographicQuestionSetId': status.demographicQuestionSetId,
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode,
        'invitations': invitations,
      });

      final resp = Map<String, dynamic>.from(cfRes.data as Map);
      final results = (resp['results'] as List?) ?? const [];
      String? firstError;
      for (final r in results) {
        if (r is Map && (r['status'] ?? '') == 'failed') {
          firstError =
              (r['error'] ?? r['sendError'] ?? r['message'] ?? '').toString();
          break;
        }
      }
      final invitedRaw = resp['invited'];
      final invited = invitedRaw is num
          ? invitedRaw.toInt()
          : int.tryParse((invitedRaw ?? '0').toString()) ?? 0;

      // ✅ 4) Refresh local invitation status (saved/remaining etc)
      if (invited == 0) {
        _snackbarController.showErrorMessage(
          firstError != null && firstError.trim().isNotEmpty
              ? 'Failed to send: $firstError'
              : 'Failed to send companion invitations. Please try again.',
        );
        return false;
      }
      await checkExistingResponse();

      if (invited == invitations.length) {
        _snackbarController.showSuccessMessage(
          'All companion invitations sent successfully!',
        );
        return true;
      }

      if (invited > 0) {
        _snackbarController.showInfoMessage(
          '$invited of ${invitations.length} companion invitations sent.',
        );
        return false;
      }

      _snackbarController.showErrorMessage(
        'Failed to send companion invitations. Please try again.',
      );
      return false;
    } on FirebaseFunctionsException catch (e) {
      error.value = e.message ?? 'Failed to send companion invitations';
      _snackbarController.showErrorMessage(error.value!);
      return false;
    } catch (e, st) {
      debugPrint('❌ sendCompanionInvitations error: $e\n$st');
      error.value = 'Failed to send companion invitations. Please try again.';
      _snackbarController.showErrorMessage(error.value!);
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
      final groupId =
          await _firestoreService.getGroupIdForMainGuest(mainGuestId);

      if (groupId == null || groupId.isEmpty) {
        return null;
      }

      // Get companion count by groupId via service layer
      final existingCompanionsCount =
          await _firestoreService.getCompanionCountByGroupId(groupId);
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
