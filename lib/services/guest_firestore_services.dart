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

  Future<void> updateInvitation(
    String invitationId,
    Map<String, dynamic> fields,
  ) async {
    await _db.collection('invitations').doc(invitationId).update(fields);
  }

  InvitationValidation validateInvitation(
    Map<String, dynamic> invitation,
    String providedToken,
  ) {
    final invToken = (invitation['token'] ?? '').toString().trim();
    if (invToken.isEmpty || invToken != providedToken) {
      return InvitationValidation(isValid: false, error: 'Invalid token');
    }

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
            isValid: false, error: 'Invitation has expired');
      }
    }

    return InvitationValidation(isValid: true);
  }

  // ---------------------------------------------------------------------------
  // Menu Responses
  // ---------------------------------------------------------------------------

  Future<bool> menuResponseExists(
    String invitationId, {
    int? companionIndex,
  }) async {
    final docId = companionIndex == null
        ? invitationId
        : '${invitationId}_companion_$companionIndex';

    final doc =
        await _db.collection('menuSelectedItemsResponses').doc(docId).get();

    return doc.exists;
  }

  Future<Map<String, dynamic>?> getMenuResponse(
    String invitationId, {
    int? companionIndex,
  }) async {
    final docId = companionIndex == null
        ? invitationId
        : '${invitationId}_companion_$companionIndex';

    final doc =
        await _db.collection('menuSelectedItemsResponses').doc(docId).get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getMenuItemsByIds({
    required String menuId,
    required List<String> itemIds,
  }) async {
    if (itemIds.isEmpty) return [];

    final menuDoc = await _db.collection('menus').doc(menuId).get();
    if (!menuDoc.exists) return [];

    final menuData = menuDoc.data();
    if (menuData == null) return [];

    final allItems = (menuData['items'] as List?) ?? [];
    final selectedItems = <Map<String, dynamic>>[];

    for (final item in allItems) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final itemId = itemMap['id']?.toString() ?? '';
      if (itemIds.contains(itemId)) selectedItems.add(itemMap);
    }

    return selectedItems;
  }

  Future<List<Map<String, dynamic>>> getMenuItemsDirectlyByIds(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];

    // whereIn max 10
    final batches = <List<String>>[];
    for (var i = 0; i < itemIds.length; i += 10) {
      batches.add(itemIds.sublist(
          i, i + 10 > itemIds.length ? itemIds.length : i + 10));
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
          'imageUrl': data['imageUrl'],
        });
      }
    }

    // preserve original order
    final ordered = <Map<String, dynamic>>[];
    for (final id in itemIds) {
      final item = results.firstWhere(
        (r) => r['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (item.isNotEmpty) ordered.add(item);
    }

    return ordered;
  }

  // ---------------------------------------------------------------------------
  // Demographic Responses
  // ---------------------------------------------------------------------------

  Future<bool> demographicResponseExists(
    String invitationId, {
    int? companionIndex,
  }) async {
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

  /// ✅ FIXED: no `.where('isDisabled'...)` and no `.orderBy(...)`
  /// because those break when isDisabled missing or index missing.
  /// We fetch all, filter locally, then sort by displayOrder.
  Future<List<DemographicQuestion>> getDemographicQuestions(
    String questionSetId,
  ) async {
    final snap = await _db
        .collection('demographicQuestions')
        .where('questionSetId', isEqualTo: questionSetId)
        .get();

    final out = <DemographicQuestion>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      // ✅ missing isDisabled => treat as enabled
      if (_asBool(data['isDisabled']) == true) continue;

      final parent = (data['parentQuestionId'] ?? '').toString().trim();
      final trigger = (data['triggerOptionId'] ?? '').toString().trim();

      out.add(DemographicQuestion(
        id: doc.id,
        text: (data['questionText'] ?? '').toString(),
        type: _normalizeQuestionType((data['questionType'] ?? '').toString()),
        isRequired: _asBool(data['isRequired']),
        displayOrder: _asInt(data['displayOrder']),
        parentQuestionId: parent.isEmpty ? null : parent,
        triggerOptionId: trigger.isEmpty ? null : trigger,
      ));
    }

    // ✅ Sort locally
    out.sort((a, b) {
      final d = a.displayOrder.compareTo(b.displayOrder);
      if (d != 0) return d;
      return a.id.compareTo(b.id);
    });

    return out;
  }

  /// ✅ Your already-fixed options loader (kept)
  Future<Map<String, List<DemographicOption>>> getDemographicOptions(
    List<String> questionIds,
  ) async {
    final Map<String, List<DemographicOption>> result = {};

    for (final ids in _chunks(questionIds, 30)) {
      final snap = await _db
          .collection('demographicQuestionOptions')
          .where('questionId', whereIn: ids)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();

        final qId = (data['questionId'] ?? '').toString().trim();
        if (qId.isEmpty) continue;

        // ✅ missing isDisabled => treat as enabled
        if (_asBool(data['isDisabled']) == true) continue;

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

    // ✅ Sort options per question locally
    for (final entry in result.entries) {
      entry.value.sort((a, b) {
        final d = a.displayOrder.compareTo(b.displayOrder);
        if (d != 0) return d;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });
    }

    return result;
  }

  Future<String?> getQuestionSetId(
    Map<String, dynamic> invitation, {
    bool allowEventFallback = false,
  }) async {
    String questionSetId =
        (invitation['demographicQuestionSetId'] ?? '').toString().trim();

    if (questionSetId.isNotEmpty) return questionSetId;
    if (!allowEventFallback) return null;

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
  // Helpers
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
  // Companion helpers + status checks (unchanged)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> getCompanions(Map<String, dynamic> invitation) {
    final raw = invitation['companions'] as List?;
    if (raw == null) return [];
    return raw.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  Map<String, dynamic>? getCompanion(
      Map<String, dynamic> invitation, int index) {
    final companions = getCompanions(invitation);
    if (index < 0 || index >= companions.length) return null;
    return companions[index];
  }

  String getCompanionName(Map<String, dynamic> companion, int index) {
    return (companion['guestName'] ??
            companion['name'] ??
            'Companion ${index + 1}')
        .toString();
  }

  String getMainGuestName(Map<String, dynamic> invitation) {
    return (invitation['guestName'] ?? 'Guest').toString();
  }

  bool isMainDemographicsComplete(Map<String, dynamic> invitation) {
    return invitation['used'] == true;
  }

  bool isMainMenuComplete(Map<String, dynamic> invitation) {
    return invitation['menuSelectionSubmitted'] == true;
  }

  bool isCompanionDemographicsComplete(Map<String, dynamic> companion) {
    return companion['demographicSubmitted'] == true;
  }

  bool isCompanionMenuComplete(Map<String, dynamic> companion) {
    return companion['menuSubmitted'] == true;
  }

  bool isFlowComplete(Map<String, dynamic> invitation) {
    if (!isMainDemographicsComplete(invitation)) return false;
    if (!isMainMenuComplete(invitation)) return false;

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

/// Demographic question model (supports conditional "Question rules")
class DemographicQuestion {
  final String id;
  final String text;
  final String type;
  final bool isRequired;
  final int displayOrder;
  final String? parentQuestionId;
  final String? triggerOptionId;
  List<DemographicOption> options;

  DemographicQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.displayOrder,
    this.parentQuestionId,
    this.triggerOptionId,
    this.options = const [],
  });

  /// Convenience getters
  bool get isBaseQuestion =>
      parentQuestionId == null || parentQuestionId!.trim().isEmpty;

  bool get isSubQuestion =>
      parentQuestionId != null &&
      parentQuestionId!.trim().isNotEmpty &&
      triggerOptionId != null &&
      triggerOptionId!.trim().isNotEmpty;

  /// Optional: clone with changes (handy in controllers)
  DemographicQuestion copyWith({
    String? id,
    String? text,
    String? type,
    bool? isRequired,
    int? displayOrder,
    String? parentQuestionId,
    String? triggerOptionId,
    List<DemographicOption>? options,
  }) {
    return DemographicQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      displayOrder: displayOrder ?? this.displayOrder,
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      triggerOptionId: triggerOptionId ?? this.triggerOptionId,
      options: options ?? this.options,
    );
  }
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
