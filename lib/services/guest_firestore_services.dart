import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for guest-facing Firestore operations.
/// 
/// This service handles all Firestore reads/writes for guest flows:
/// - RSVP responses
/// - Demographic submissions
/// - Menu selections
/// - Invitation status
class GuestFirestoreServices {
  final FirebaseFirestore _db;

  GuestFirestoreServices({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Invitations
  // ---------------------------------------------------------------------------

  /// Fetches an invitation by ID.
  /// 
  /// Returns the invitation data map or null if not found.
  /// Optionally force server fetch to get latest data.
  Future<Map<String, dynamic>?> getInvitation(
    String invitationId, {
    bool forceServer = false,
  }) async {
    final doc = await _db
        .collection('invitations')
        .doc(invitationId)
        .get(forceServer ? const GetOptions(source: Source.server) : null);
    
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Updates invitation fields atomically.
  Future<void> updateInvitation(
    String invitationId,
    Map<String, dynamic> fields,
  ) async {
    await _db.collection('invitations').doc(invitationId).update(fields);
  }

  /// Validates invitation token and expiry.
  /// 
  /// Returns a validation result with success status and error message if any.
  InvitationValidation validateInvitation(
    Map<String, dynamic> invitation,
    String providedToken,
  ) {
    // Token check
    final invToken = (invitation['token'] ?? '').toString().trim();
    if (invToken.isEmpty || invToken != providedToken) {
      return InvitationValidation(
        isValid: false,
        error: 'Invalid token',
      );
    }

    // Expiry check
    final expiresAt = invitation['expiresAt'];
    if (expiresAt != null) {
      DateTime? expiryDate;
      if (expiresAt is Timestamp) {
        expiryDate = expiresAt.toDate();
      } else if (expiresAt is DateTime) {
        expiryDate = expiresAt;
      }
      
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        return InvitationValidation(
          isValid: false,
          error: 'Invitation has expired',
        );
      }
    }

    return InvitationValidation(isValid: true);
  }

  // ---------------------------------------------------------------------------
  // Menu Responses
  // ---------------------------------------------------------------------------

  /// Checks if a menu response document exists for an invitation/companion.
  /// 
  /// For main guest: docId = invitationId
  /// For companion: docId = invitationId_companion_{index}
  Future<bool> menuResponseExists(
    String invitationId, {
    int? companionIndex,
  }) async {
    final docId = companionIndex == null
        ? invitationId
        : '${invitationId}_companion_$companionIndex';
    
    final doc = await _db
        .collection('menuSelectedItemsResponses')
        .doc(docId)
        .get();
    
    return doc.exists;
  }

  /// Gets menu response data if it exists.
  Future<Map<String, dynamic>?> getMenuResponse(
    String invitationId, {
    int? companionIndex,
  }) async {
    final docId = companionIndex == null
        ? invitationId
        : '${invitationId}_companion_$companionIndex';
    
    final doc = await _db
        .collection('menuSelectedItemsResponses')
        .doc(docId)
        .get();
    
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Fetches menu items by their IDs from the menu document.
  /// 
  /// Used for read-only preview mode where we only have item IDs.
  Future<List<Map<String, dynamic>>> getMenuItemsByIds({
    required String menuId,
    required List<String> itemIds,
  }) async {
    if (itemIds.isEmpty) return [];

    // Fetch the menu document
    final menuDoc = await _db.collection('menus').doc(menuId).get();
    if (!menuDoc.exists) return [];

    final menuData = menuDoc.data();
    if (menuData == null) return [];

    // Get items from the menu
    final allItems = (menuData['items'] as List?) ?? [];
    
    // Filter to only the selected item IDs
    final selectedItems = <Map<String, dynamic>>[];
    for (final item in allItems) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final itemId = itemMap['id']?.toString() ?? '';
      if (itemIds.contains(itemId)) {
        selectedItems.add(itemMap);
      }
    }

    return selectedItems;
  }

  /// Fetches menu items directly from the menu_items collection by document IDs.
  /// 
  /// This doesn't require a menuId - items are fetched by their document IDs.
  /// Used for read-only preview when we only have selectedMenuItemIds.
  Future<List<Map<String, dynamic>>> getMenuItemsDirectlyByIds(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    
    // Firestore 'whereIn' supports max 10 items, so batch the queries
    final batches = <List<String>>[];
    for (var i = 0; i < itemIds.length; i += 10) {
      batches.add(itemIds.sublist(i, i + 10 > itemIds.length ? itemIds.length : i + 10));
    }

    for (final batch in batches) {
      final snapshot = await _db
          .collection('menu_items')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDisabled'] == true) continue;

        results.add({
          'id': doc.id,
          'name': data['name'] ?? data['title'] ?? 'Menu item',
          'description': (data['description'] ?? '').toString(),
          'price': data['price'],
          'category': data['category'] ?? '',
          'foodType': data['foodType'],
        });
      }
    }

    // Preserve the original order from itemIds
    final orderedResults = <Map<String, dynamic>>[];
    for (final id in itemIds) {
      final item = results.firstWhere(
        (r) => r['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (item.isNotEmpty) {
        orderedResults.add(item);
      }
    }

    return orderedResults;
  }

  // ---------------------------------------------------------------------------
  // Demographic Responses
  // ---------------------------------------------------------------------------

  /// Checks if a demographic response exists for an invitation/companion.
  Future<bool> demographicResponseExists(
    String invitationId, {
    int? companionIndex,
  }) async {
    // For main guest, check the invitation's responseId field
    // For companions, check companions[index].demographicResponseId
    final invitation = await getInvitation(invitationId);
    if (invitation == null) return false;

    if (companionIndex == null) {
      return invitation['used'] == true;
    } else {
      final companions = (invitation['companions'] as List?) ?? [];
      if (companionIndex >= companions.length) return false;
      final companion = companions[companionIndex] as Map<String, dynamic>;
      return companion['demographicSubmitted'] == true;
    }
  }

  /// Gets the demographic question set by ID.
  Future<Map<String, dynamic>?> getDemographicQuestionSet(
    String questionSetId,
  ) async {
    final doc = await _db
        .collection('demographicQuestionSets')
        .doc(questionSetId)
        .get();
    
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Gets all demographic questions for a question set.
  /// Questions are returned ordered by displayOrder.
  Future<List<DemographicQuestion>> getDemographicQuestions(
    String questionSetId,
  ) async {
    final snap = await _db
        .collection('demographicQuestions')
        .where('questionSetId', isEqualTo: questionSetId)
        .where('isDisabled', isEqualTo: false)
        .orderBy('displayOrder')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return DemographicQuestion(
        id: doc.id,
        text: (data['questionText'] ?? '').toString(),
        type: _normalizeQuestionType((data['questionType'] ?? '').toString()),
        isRequired: _asBool(data['isRequired']),
        displayOrder: _asInt(data['displayOrder']),
      );
    }).toList();
  }

  /// Gets all options for a list of question IDs.
  /// Returns a map of questionId -> list of options (ordered by displayOrder).
  Future<Map<String, List<DemographicOption>>> getDemographicOptions(
    List<String> questionIds,
  ) async {
    final Map<String, List<DemographicOption>> result = {};

    // Firestore limits whereIn to 30 items, so we chunk
    for (final ids in _chunks(questionIds, 30)) {
      final snap = await _db
          .collection('demographicQuestionOptions')
          .where('questionId', whereIn: ids)
          .where('isDisabled', isEqualTo: false)
          .orderBy('displayOrder')
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final qId = (data['questionId'] ?? '').toString();
        if (qId.isEmpty) continue;

        final opt = DemographicOption(
          id: doc.id,
          questionId: qId,
          label: (data['label'] ?? '').toString(),
          value: (data['value'] ?? '').toString(),
          requiresFreeText: _asBool(data['requiresFreeText']),
          displayOrder: _asInt(data['displayOrder']),
        );

        result.putIfAbsent(qId, () => []).add(opt);
      }
    }

    return result;
  }

  /// Gets the question set ID from an invitation, with event fallback for hosts.
  Future<String?> getQuestionSetId(
    Map<String, dynamic> invitation, {
    bool allowEventFallback = false,
  }) async {
    String questionSetId =
        (invitation['demographicQuestionSetId'] ?? '').toString().trim();

    if (questionSetId.isNotEmpty) return questionSetId;

    if (!allowEventFallback) return null;

    // Fallback from event (host only)
    final eventId = (invitation['eventId'] ?? '').toString().trim();
    if (eventId.isEmpty) return null;

    final byDoc = await _db.collection('events').doc(eventId).get();
    if (byDoc.exists) {
      final eventData = byDoc.data();
      return (eventData?['selectedDemographicQuestionSetId'] ?? '')
          .toString()
          .trim();
    }

    final q = await _db
        .collection('events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      final eventData = q.docs.first.data();
      return (eventData['selectedDemographicQuestionSetId'] ?? '')
          .toString()
          .trim();
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  static String _normalizeQuestionType(String type) {
    switch (type) {
      case 'short_answer':
      case 'paragraph':
      case 'multiple_choice':
      case 'checkboxes':
      case 'dropdown':
        return type;
      case 'text':
        return 'short_answer';
      case 'single_choice':
        return 'multiple_choice';
      case 'multi_choice':
        return 'checkboxes';
      default:
        return 'multiple_choice';
    }
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? fallback;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static List<List<T>> _chunks<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      final end = (i + size > list.length) ? list.length : i + size;
      out.add(list.sublist(i, end));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Companions Helpers
  // ---------------------------------------------------------------------------

  /// Gets the list of companions from an invitation.
  List<Map<String, dynamic>> getCompanions(Map<String, dynamic> invitation) {
    final raw = invitation['companions'] as List?;
    if (raw == null) return [];
    return raw.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  /// Gets a specific companion by index.
  Map<String, dynamic>? getCompanion(
    Map<String, dynamic> invitation,
    int index,
  ) {
    final companions = getCompanions(invitation);
    if (index < 0 || index >= companions.length) return null;
    return companions[index];
  }

  /// Gets the companion's display name.
  String getCompanionName(Map<String, dynamic> companion, int index) {
    return (companion['guestName'] ?? 
            companion['name'] ?? 
            'Companion ${index + 1}').toString();
  }

  /// Gets the main guest's display name.
  String getMainGuestName(Map<String, dynamic> invitation) {
    return (invitation['guestName'] ?? 'Guest').toString();
  }

  // ---------------------------------------------------------------------------
  // Status Checks
  // ---------------------------------------------------------------------------

  /// Checks if main guest has completed demographics.
  bool isMainDemographicsComplete(Map<String, dynamic> invitation) {
    return invitation['used'] == true;
  }

  /// Checks if main guest has completed menu selection.
  bool isMainMenuComplete(Map<String, dynamic> invitation) {
    return invitation['menuSelectionSubmitted'] == true;
  }

  /// Checks if a companion has completed demographics.
  bool isCompanionDemographicsComplete(Map<String, dynamic> companion) {
    return companion['demographicSubmitted'] == true;
  }

  /// Checks if a companion has completed menu selection.
  bool isCompanionMenuComplete(Map<String, dynamic> companion) {
    return companion['menuSubmitted'] == true;
  }

  /// Checks if all people (main + companions) have completed the entire flow.
  bool isFlowComplete(Map<String, dynamic> invitation) {
    // Main guest checks
    if (!isMainDemographicsComplete(invitation)) return false;
    if (!isMainMenuComplete(invitation)) return false;

    // Companions checks
    final companions = getCompanions(invitation);
    for (final c in companions) {
      if (!isCompanionDemographicsComplete(c)) return false;
      if (!isCompanionMenuComplete(c)) return false;
    }

    return true;
  }
}

/// Result of invitation validation.
class InvitationValidation {
  final bool isValid;
  final String? error;

  InvitationValidation({
    required this.isValid,
    this.error,
  });
}

/// Demographic question model.
class DemographicQuestion {
  final String id;
  final String text;
  final String type;
  final bool isRequired;
  final int displayOrder;
  List<DemographicOption> options;

  DemographicQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.displayOrder,
    this.options = const [],
  });
}

/// Demographic option model.
class DemographicOption {
  final String id;
  final String questionId;
  final String label;
  final String value;
  final bool requiresFreeText;
  final int displayOrder;

  const DemographicOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.value,
    required this.requiresFreeText,
    required this.displayOrder,
  });
}
