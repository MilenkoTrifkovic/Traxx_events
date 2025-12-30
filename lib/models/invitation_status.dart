import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing the status of an invitation and RSVP response
/// Used when checking if a guest has already responded
/// 
/// Firestore Schema:
/// - invitationId: Document ID
/// - eventId: Event reference
/// - guestId: Guest document reference
/// - guestEmail: Guest email address
/// - guestName: Guest display name
/// - organisationId: Organisation reference
/// - demographicQuestionSetId: Question set reference
/// - maxGuestInvite: Maximum number of additional guests allowed
/// - token: Unique invitation token (48 chars)
/// - sent: Email sent status
/// - sentAt: When invitation email was sent
/// - postmarkMessageId: Email service message ID
/// - used: Has guest started responding (demographics/menu)
/// - usedAt: When guest first accessed the invitation
/// - createdAt: When invitation was created
/// - expiresAt: Invitation expiration date
/// - isAttending: RSVP response (true/false/null=pending) - NEW FIELD
/// - rsvpSubmittedAt: When RSVP was submitted - NEW FIELD
/// - declineReason: Optional reason for declining - NEW FIELD
/// - responseId: Guest response document reference
/// - menuSelectionSubmitted: Has menu been submitted
/// - menuSelectionSubmittedAt: When menu was submitted
class InvitationStatus {
  final String invitationId;
  final String eventId;
  final String guestId;
  final String guestEmail;
  final String? guestName;
  final String organisationId;
  final String? demographicQuestionSetId;
  final int maxGuestInvite;
  final String token;
  final bool sent;
  final DateTime? sentAt;
  final String? postmarkMessageId;
  final bool used;
  final DateTime? usedAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  
  // RSVP fields (new flow)
  final bool hasResponded;
  final bool? isAttending;
  final DateTime? rsvpSubmittedAt;
  final String? declineReason;
  
  // Companion selection
  final int? companionsCount;
  final DateTime? companionsSubmittedAt;
  final bool? isInvitingCompanionsByEmail; // Whether primary guest wants to send email invites to companions
  final List<Map<String, dynamic>> companions; // List of already added companions
  
  // Response tracking
  final String? responseId;
  final bool menuSelectionSubmitted;
  final DateTime? menuSelectionSubmittedAt;

  const InvitationStatus({
    required this.invitationId,
    required this.eventId,
    required this.guestId,
    required this.guestEmail,
    this.guestName,
    required this.organisationId,
    this.demographicQuestionSetId,
    this.maxGuestInvite = 0,
    required this.token,
    required this.sent,
    this.sentAt,
    this.postmarkMessageId,
    required this.used,
    this.usedAt,
    this.createdAt,
    this.expiresAt,
    required this.hasResponded,
    this.isAttending,
    this.rsvpSubmittedAt,
    this.declineReason,
    this.companionsCount,
    this.companionsSubmittedAt,
    this.isInvitingCompanionsByEmail,
    this.companions = const [], // Default to empty list
    this.responseId,
    required this.menuSelectionSubmitted,
    this.menuSelectionSubmittedAt,
  });

  /// Create InvitationStatus from Firestore document
  factory InvitationStatus.fromFirestore(
    String invitationId,
    Map<String, dynamic> data,
  ) {
    final isAttending = data['isAttending'] as bool?;
    
    // Convert Timestamps to DateTime
    final rsvpTimestamp = data['rsvpSubmittedAt'] as Timestamp?;
    final sentAtTimestamp = data['sentAt'] as Timestamp?;
    final usedAtTimestamp = data['usedAt'] as Timestamp?;
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final expiresAtTimestamp = data['expiresAt'] as Timestamp?;
    final companionsSubmittedAtTimestamp = data['companionsSubmittedAt'] as Timestamp?;
    final menuSubmittedAtTimestamp = data['menuSelectionSubmittedAt'] as Timestamp?;

    return InvitationStatus(
      invitationId: invitationId,
      eventId: data['eventId'] as String? ?? '',
      guestId: data['guestId'] as String? ?? '',
      guestEmail: data['guestEmail'] as String? ?? '',
      guestName: data['guestName'] as String?,
      organisationId: data['organisationId'] as String? ?? '',
      demographicQuestionSetId: data['demographicQuestionSetId'] as String?,
      maxGuestInvite: data['maxGuestInvite'] as int? ?? 0,
      token: data['token'] as String? ?? '',
      sent: data['sent'] as bool? ?? false,
      sentAt: sentAtTimestamp?.toDate(),
      postmarkMessageId: data['postmarkMessageId'] as String?,
      used: data['used'] as bool? ?? false,
      usedAt: usedAtTimestamp?.toDate(),
      createdAt: createdAtTimestamp?.toDate(),
      expiresAt: expiresAtTimestamp?.toDate(),
      hasResponded: isAttending != null,
      isAttending: isAttending,
      rsvpSubmittedAt: rsvpTimestamp?.toDate(),
      declineReason: data['declineReason'] as String?,
      companionsCount: data['companionsCount'] as int?,
      companionsSubmittedAt: companionsSubmittedAtTimestamp?.toDate(),
      isInvitingCompanionsByEmail: data['isInvitingCompanionsByEmail'] as bool?,
      companions: (data['companions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      responseId: data['responseId'] as String?,
      menuSelectionSubmitted: data['menuSelectionSubmitted'] as bool? ?? false,
      menuSelectionSubmittedAt: menuSubmittedAtTimestamp?.toDate(),
    );
  }

  /// Create InvitationStatus from Firestore DocumentSnapshot
  factory InvitationStatus.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Invitation not found');
    }
    return InvitationStatus.fromFirestore(snapshot.id, snapshot.data()!);
  }

  /// Check if RSVP response indicates attending
  bool get isConfirmedAttending => hasResponded && isAttending == true;

  /// Check if RSVP response indicates not attending
  bool get isConfirmedNotAttending => hasResponded && isAttending == false;

  /// Check if invitation is still pending response
  bool get isPending => !hasResponded;

  /// Check if invitation has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if invitation is still valid (sent, not expired)
  bool get isValid => sent && !isExpired;

  /// Check if guest has submitted demographics (used flag)
  bool get hasDemographics => used == true;

  /// Check if guest is allowed to invite companions (based on maxGuestInvite)
  bool get canInviteCompanions => maxGuestInvite > 0;

  /// Check if guest has submitted companion count selection
  bool get hasSubmittedCompanionCount => companionsCount != null;

  /// Get the number of companions already added to Firestore
  int get savedCompanionsCount => companions.length;

  /// Get the number of remaining companions to create
  int get remainingCompanionsToCreate {
    final total = companionsCount ?? 0;
    final saved = savedCompanionsCount;
    return (total - saved).clamp(0, total);
  }

  /// Check if guest has submitted menu selection
  bool get hasMenuSelection => menuSelectionSubmitted == true;

  /// Check if there are demographics questions for this event
  bool get requiresDemographics => demographicQuestionSetId != null && demographicQuestionSetId!.isNotEmpty;

  /// Check if all required steps are completed
  /// Returns true only if guest has done RSVP, demographics (if required), companions (if allowed), and menu
  bool get isFullyCompleted {
    if (!hasResponded || !isConfirmedAttending) return false;
    // If attending, must complete demographics (if required) - main guest AND all companions
    if (requiresDemographics) {
      if (!hasDemographics) return false;
      // Check all companions have completed demographics
      for (final companion in companions) {
        if (companion['demographicSubmitted'] != true) return false;
      }
    }
    // Must complete companion selection if allowed to invite companions
    if (canInviteCompanions && !hasSubmittedCompanionCount) return false;
    // Must complete menu selection - main guest AND all companions
    if (!hasMenuSelection) return false;
    for (final companion in companions) {
      if (companion['menuSubmitted'] != true) return false;
    }
    return true;
  }

  /// Get the next incomplete step for an attending guest
  /// Returns null if not attending or all steps completed
  /// Returns 'companions' if guest can invite companions but hasn't selected count yet
  /// Returns 'demographics' if demographics required but not completed
  /// Returns 'menu' if menu not completed
  String? get nextIncompleteStep {
    if (!hasResponded || !isConfirmedAttending) return null;
    
    // Check companion selection (if guest is allowed to invite companions)
    // Case 1: maxGuestInvite > 0 but companionsCount not selected yet
    if (maxGuestInvite > 0 && companionsCount == null) {
      return 'companions';
    }
    
    // Case 2: companionsCount selected but not all companions created yet
    if (companionsCount != null && companionsCount! > 0 && companions.length < companionsCount!) {
      return 'companions';
    }
    
    // Check demographics (if required) - main guest AND all companions
    if (requiresDemographics) {
      // Check main guest demographics
      if (!hasDemographics) {
        return 'demographics';
      }
      
      // Check all companions have completed demographics
      for (final companion in companions) {
        if (companion['demographicSubmitted'] != true) {
          return 'demographics';
        }
      }
    }
    
    // Check menu selection - main guest AND all companions
    if (!hasMenuSelection) {
      return 'menu';
    }
    
    // Check all companions have completed menu selection
    for (final companion in companions) {
      if (companion['menuSubmitted'] != true) {
        return 'menu';
      }
    }
    
    // All steps completed
    return null;
  }

  /// Get a user-friendly status message
  String get statusMessage {
    if (!hasResponded) return 'Awaiting response';
    if (isAttending == true) return 'Attending';
    if (isAttending == false) return 'Not attending';
    return 'Unknown';
  }

  /// Convert to Map (for debugging or logging)
  Map<String, dynamic> toMap() {
    return {
      'invitationId': invitationId,
      'eventId': eventId,
      'guestId': guestId,
      'guestEmail': guestEmail,
      'guestName': guestName,
      'organisationId': organisationId,
      'demographicQuestionSetId': demographicQuestionSetId,
      'maxGuestInvite': maxGuestInvite,
      'token': token,
      'sent': sent,
      'sentAt': sentAt?.toIso8601String(),
      'postmarkMessageId': postmarkMessageId,
      'used': used,
      'usedAt': usedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'hasResponded': hasResponded,
      'isAttending': isAttending,
      'rsvpSubmittedAt': rsvpSubmittedAt?.toIso8601String(),
      'declineReason': declineReason,
      'companionsCount': companionsCount,
      'companionsSubmittedAt': companionsSubmittedAt?.toIso8601String(),
      'responseId': responseId,
      'menuSelectionSubmitted': menuSelectionSubmitted,
      'menuSelectionSubmittedAt': menuSelectionSubmittedAt?.toIso8601String(),
      'statusMessage': statusMessage,
      'isExpired': isExpired,
      'isValid': isValid,
    };
  }

  @override
  String toString() {
    return 'InvitationStatus(id: $invitationId, guest: $guestName ($guestEmail), status: $statusMessage, used: $used, menuSubmitted: $menuSelectionSubmitted)';
  }

  /// Create a copy with updated fields (for immutable state updates)
  InvitationStatus copyWith({
    String? invitationId,
    String? eventId,
    String? guestId,
    String? guestEmail,
    String? guestName,
    String? organisationId,
    String? demographicQuestionSetId,
    int? maxGuestInvite,
    String? token,
    bool? sent,
    DateTime? sentAt,
    String? postmarkMessageId,
    bool? used,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? hasResponded,
    bool? isAttending,
    DateTime? rsvpSubmittedAt,
    String? declineReason,
    int? companionsCount,
    DateTime? companionsSubmittedAt,
    bool? isInvitingCompanionsByEmail,
    List<Map<String, dynamic>>? companions,
    String? responseId,
    bool? menuSelectionSubmitted,
    DateTime? menuSelectionSubmittedAt,
  }) {
    return InvitationStatus(
      invitationId: invitationId ?? this.invitationId,
      eventId: eventId ?? this.eventId,
      guestId: guestId ?? this.guestId,
      guestEmail: guestEmail ?? this.guestEmail,
      guestName: guestName ?? this.guestName,
      organisationId: organisationId ?? this.organisationId,
      demographicQuestionSetId: demographicQuestionSetId ?? this.demographicQuestionSetId,
      maxGuestInvite: maxGuestInvite ?? this.maxGuestInvite,
      token: token ?? this.token,
      sent: sent ?? this.sent,
      sentAt: sentAt ?? this.sentAt,
      postmarkMessageId: postmarkMessageId ?? this.postmarkMessageId,
      used: used ?? this.used,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hasResponded: hasResponded ?? this.hasResponded,
      isAttending: isAttending ?? this.isAttending,
      rsvpSubmittedAt: rsvpSubmittedAt ?? this.rsvpSubmittedAt,
      declineReason: declineReason ?? this.declineReason,
      companionsCount: companionsCount ?? this.companionsCount,
      companionsSubmittedAt: companionsSubmittedAt ?? this.companionsSubmittedAt,
      isInvitingCompanionsByEmail: isInvitingCompanionsByEmail ?? this.isInvitingCompanionsByEmail,
      companions: companions ?? this.companions,
      responseId: responseId ?? this.responseId,
      menuSelectionSubmitted: menuSelectionSubmitted ?? this.menuSelectionSubmitted,
      menuSelectionSubmittedAt: menuSelectionSubmittedAt ?? this.menuSelectionSubmittedAt,
    );
  }
}
