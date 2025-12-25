import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/invitation_status.dart';

/// Service for handling guest invitation responses and RSVP
/// Manages: invitations, demographicQuestionsResponses, menuSelectedItemsResponses
class InvitationResponseServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to invitations collection
  late final CollectionReference<Map<String, dynamic>> invitationsRef;

  /// Reference to demographic responses collection
  late final CollectionReference<Map<String, dynamic>>
      demographicResponsesRef;

  /// Reference to menu selection responses collection
  late final CollectionReference<Map<String, dynamic>> menuResponsesRef;

  InvitationResponseServices() {
    invitationsRef = _db.collection('invitations');
    demographicResponsesRef = _db.collection('demographicQuestionsResponses');
    menuResponsesRef = _db.collection('menuSelectedItemsResponses');
  }

  // ============================================================================
  // RSVP Methods
  // ============================================================================

  /// Submit RSVP response (attending or not attending)
  Future<void> submitRsvp({
    required String invitationId,
    required bool isAttending,
    String? declineReason,
  }) async {
    final updateData = {
      'isAttending': isAttending,
      'rsvpSubmittedAt': FieldValue.serverTimestamp(),
    };

    if (!isAttending && declineReason != null && declineReason.isNotEmpty) {
      updateData['declineReason'] = declineReason;
    }

    await invitationsRef.doc(invitationId).update(updateData);
  }

  /// Get invitation by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getInvitation(
    String invitationId,
  ) async {
    return await invitationsRef.doc(invitationId).get();
  }

  /// Get invitation by email and event
  Future<QuerySnapshot<Map<String, dynamic>>> getInvitationByEmailAndEvent({
    required String email,
    required String eventId,
  }) async {
    return await invitationsRef
        .where('email', isEqualTo: email)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
  }

  /// Check if invitation token is valid
  Future<bool> validateInvitationToken({
    required String invitationId,
    required String token,
  }) async {
    try {
      final doc = await invitationsRef.doc(invitationId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      return data?['token'] == token;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has already responded to RSVP
  /// Returns invitation data with RSVP status
  Future<InvitationStatus?> checkRsvpStatus({
    required String invitationId,
  }) async {
    try {
      final doc = await invitationsRef.doc(invitationId).get();
      if (!doc.exists || doc.data() == null) return null;

      return InvitationStatus.fromSnapshot(doc);
    } catch (e) {
      print('❌ Error checking RSVP status: $e');
      return null;
    }
  }

  // ============================================================================
  // Demographic Response Methods
  // ============================================================================

  /// Submit demographic questions response
  Future<void> submitDemographicResponse({
    required String invitationId,
    required String eventId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final responseId = invitationId; // Use invitationId as responseId

    await demographicResponsesRef.doc(responseId).set({
      'invitationId': invitationId,
      'eventId': eventId,
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Update invitation to mark demographics as completed
    await invitationsRef.doc(invitationId).update({
      'used': true,
      'demographicsSubmittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get demographic response for an invitation
  Future<DocumentSnapshot<Map<String, dynamic>>> getDemographicResponse(
    String invitationId,
  ) async {
    return await demographicResponsesRef.doc(invitationId).get();
  }

  // ============================================================================
  // Menu Response Methods
  // ============================================================================

  /// Submit menu selection response
  Future<void> submitMenuResponse({
    required String invitationId,
    required String eventId,
    required List<String> selectedMenuItemIds,
  }) async {
    final responseId = invitationId; // Use invitationId as responseId

    await menuResponsesRef.doc(responseId).set({
      'invitationId': invitationId,
      'eventId': eventId,
      'selectedMenuItemIds': selectedMenuItemIds,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Update invitation to mark menu as completed
    await invitationsRef.doc(invitationId).update({
      'menuSelectionSubmitted': true,
      'menuSubmittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get menu response for an invitation
  Future<DocumentSnapshot<Map<String, dynamic>>> getMenuResponse(
    String invitationId,
  ) async {
    return await menuResponsesRef.doc(invitationId).get();
  }

  // ============================================================================
  // Query Methods for Analytics
  // ============================================================================

  /// Get all invitations for an event
  Future<QuerySnapshot<Map<String, dynamic>>> getInvitationsForEvent(
    String eventId,
  ) async {
    return await invitationsRef.where('eventId', isEqualTo: eventId).get();
  }

  /// Get all demographic responses for an event
  Future<QuerySnapshot<Map<String, dynamic>>> getDemographicResponsesForEvent(
    String eventId,
  ) async {
    return await demographicResponsesRef
        .where('eventId', isEqualTo: eventId)
        .get();
  }

  /// Get all menu responses for an event
  Future<QuerySnapshot<Map<String, dynamic>>> getMenuResponsesForEvent(
    String eventId,
  ) async {
    return await menuResponsesRef.where('eventId', isEqualTo: eventId).get();
  }

  /// Get RSVP statistics for an event
  Future<Map<String, int>> getRsvpStats(String eventId) async {
    final invitations = await getInvitationsForEvent(eventId);

    int total = invitations.size;
    int attending = 0;
    int declined = 0;
    int pending = 0;

    for (final doc in invitations.docs) {
      final data = doc.data();
      final isAttending = data['isAttending'];

      if (isAttending == true) {
        attending++;
      } else if (isAttending == false) {
        declined++;
      } else {
        pending++;
      }
    }

    return {
      'total': total,
      'attending': attending,
      'declined': declined,
      'pending': pending,
    };
  }

  // ============================================================================
  // Stream Methods (for real-time updates)
  // ============================================================================

  /// Stream invitation data
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamInvitation(
    String invitationId,
  ) {
    return invitationsRef.doc(invitationId).snapshots();
  }

  /// Stream invitations for an event
  Stream<QuerySnapshot<Map<String, dynamic>>> streamInvitationsForEvent(
    String eventId,
  ) {
    return invitationsRef.where('eventId', isEqualTo: eventId).snapshots();
  }
}
