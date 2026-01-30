/// Helper utilities for managing the guest response flow.
///
/// Flow: RSVP → Companions Info → Demographics (main) → Menu (main) → Demographics (companion 1) → Menu (companion 1) → ... → Thank You
///
/// This file provides:
/// - Navigation URL builders
/// - Next step determination logic
/// - Completion status checking

/// Represents the current state of response progress for an invitation
class ResponseFlowState {
  final String invitationId;
  final String token;

  // Main guest status
  final bool mainDemographicsSubmitted;
  final bool mainMenuSubmitted;

  // Companions list with their individual status
  final List<CompanionStatus> companions;

  // Whether demographics are required for this event
  final bool requiresDemographics;

  const ResponseFlowState({
    required this.invitationId,
    required this.token,
    required this.mainDemographicsSubmitted,
    required this.mainMenuSubmitted,
    required this.companions,
    this.requiresDemographics =
        true, // Default to true for backward compatibility
  });

  /// Create from invitation document data
  factory ResponseFlowState.fromInvitation(
      Map<String, dynamic> inv, String token,
      {String? invitationIdOverride}) {
    final companionsList = (inv['companions'] as List?)
            ?.map((c) =>
                CompanionStatus.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList() ??
        [];

    // Use override if provided, otherwise try to get from invitation data
    final invId =
        invitationIdOverride ?? (inv['invitationId'] ?? '').toString();

    // Check if demographics are required (has demographicQuestionSetId)
    final demographicQuestionSetId = inv['demographicQuestionSetId'];
    final requiresDemographics = demographicQuestionSetId != null &&
        demographicQuestionSetId.toString().trim().isNotEmpty;

    return ResponseFlowState(
      invitationId: invId,
      token: token,
      mainDemographicsSubmitted: inv['used'] == true,
      mainMenuSubmitted: inv['menuSelectionSubmitted'] == true,
      companions: companionsList,
      requiresDemographics: requiresDemographics,
    );
  }

  /// Check if all demographics (main + all companions) are complete
  /// Returns true if demographics are not required, or if all are submitted
  bool get allDemographicsComplete {
    if (!requiresDemographics) return true;
    if (!mainDemographicsSubmitted) return false;
    return companions
        .where((c) => !c.isExplicitNo)
        .every((c) => c.demographicSubmitted);
  }

  /// Check if all menu selections (main + all companions) are complete
  bool get allMenusComplete {
    if (!mainMenuSubmitted) return false;
    return companions
        .where((c) => !c.isExplicitNo)
        .every((c) => c.menuSubmitted);
  }

  /// Check if entire flow is complete
  bool get isComplete => allDemographicsComplete && allMenusComplete;

  /// Get the next step info for navigation
  /// New flow: Demographics (main) → Menu (main) → Demographics (companion 1) → Menu (companion 1) → ...
  NextStepInfo getNextStep() {
    if (requiresDemographics && !mainDemographicsSubmitted) {
      return const NextStepInfo(
          step: ResponseStep.demographics,
          companionIndex: null,
          companionName: null,
          isMainGuest: true);
    }
    if (!mainMenuSubmitted) {
      return const NextStepInfo(
          step: ResponseStep.menu,
          companionIndex: null,
          companionName: null,
          isMainGuest: true);
    }

    for (int i = 0; i < companions.length; i++) {
      final c = companions[i];

      // ✅ skip not-attending companions
      if (c.isExplicitNo) continue;

      if (requiresDemographics && !c.demographicSubmitted) {
        return NextStepInfo(
            step: ResponseStep.demographics,
            companionIndex: i,
            companionName: c.name,
            isMainGuest: false);
      }
      if (!c.menuSubmitted) {
        return NextStepInfo(
            step: ResponseStep.menu,
            companionIndex: i,
            companionName: c.name,
            isMainGuest: false);
      }
    }

    return const NextStepInfo(
        step: ResponseStep.thankYou,
        companionIndex: null,
        companionName: null,
        isMainGuest: true);
  }

  /// Build the URL for the next step
  String buildNextStepUrl() {
    final next = getNextStep();
    return next.buildUrl(invitationId, token);
  }
}

/// Status for a single companion
class CompanionStatus {
  final String? guestId;
  final String name;
  final String? email;

  final bool attendingSubmitted;
  final bool? isAttending;

  final bool demographicSubmitted;
  final bool menuSubmitted;

  const CompanionStatus({
    this.guestId,
    required this.name,
    this.email,
    required this.attendingSubmitted,
    required this.isAttending,
    required this.demographicSubmitted,
    required this.menuSubmitted,
  });

  factory CompanionStatus.fromMap(Map<String, dynamic> map) {
    return CompanionStatus(
      guestId: map['guestId']?.toString(),
      // ✅ support both shapes
      name: (map['guestName'] ?? map['name'] ?? 'Companion').toString(),
      email: (map['guestEmail'] ?? map['email'])?.toString(),

      attendingSubmitted: map['attendingSubmitted'] == true,
      isAttending:
          map['isAttending'] is bool ? map['isAttending'] as bool : null,

      demographicSubmitted: map['demographicSubmitted'] == true,
      menuSubmitted: map['menuSubmitted'] == true,
    );
  }

  bool get isExplicitNo => attendingSubmitted == true && isAttending == false;
}

/// The possible steps in the response flow
enum ResponseStep {
  demographics,
  menu,
  thankYou,
}

/// Info about the next step to navigate to
class NextStepInfo {
  final ResponseStep step;
  final int? companionIndex;
  final String? companionName;
  final bool isMainGuest;

  const NextStepInfo({
    required this.step,
    required this.companionIndex,
    required this.companionName,
    required this.isMainGuest,
  });

  /// Build the URL for this step
  String buildUrl(String invitationId, String token) {
    final encodedId = Uri.encodeComponent(invitationId);
    final encodedToken = Uri.encodeComponent(token);

    switch (step) {
      case ResponseStep.demographics:
        var url = '/demographics?invitationId=$encodedId&token=$encodedToken';
        if (companionIndex != null) {
          url += '&companionIndex=$companionIndex';
          if (companionName != null && companionName!.isNotEmpty) {
            url += '&companionName=${Uri.encodeComponent(companionName!)}';
          }
        }
        return url;

      case ResponseStep.menu:
        var url = '/menu-selection?invitationId=$encodedId&token=$encodedToken';
        if (companionIndex != null) {
          url += '&companionIndex=$companionIndex';
          if (companionName != null && companionName!.isNotEmpty) {
            url += '&companionName=${Uri.encodeComponent(companionName!)}';
          }
        }
        return url;

      case ResponseStep.thankYou:
        return '/thank-you?invitationId=$encodedId&token=$encodedToken';
    }
  }

  /// Get a display label for this step
  String getDisplayLabel() {
    switch (step) {
      case ResponseStep.demographics:
        if (isMainGuest) {
          return 'Your Demographics';
        } else {
          return 'Demographics for ${companionName ?? "Companion ${(companionIndex ?? 0) + 1}"}';
        }

      case ResponseStep.menu:
        if (isMainGuest) {
          return 'Your Menu Selection';
        } else {
          return 'Menu for ${companionName ?? "Companion ${(companionIndex ?? 0) + 1}"}';
        }

      case ResponseStep.thankYou:
        return 'Complete';
    }
  }
}

/// Extension to help with URL query parameter parsing
extension ResponseFlowUrlParser on Uri {
  /// Parse companion index from query parameters
  int? get companionIndex {
    final param = queryParameters['companionIndex'];
    if (param == null || param.isEmpty) return null;
    return int.tryParse(param);
  }

  /// Parse companion name from query parameters
  String? get companionName {
    return queryParameters['companionName'];
  }

  /// Parse invitation ID from query parameters
  String get invitationId => queryParameters['invitationId'] ?? '';

  /// Parse token from query parameters
  String get token => queryParameters['token'] ?? '';
}
