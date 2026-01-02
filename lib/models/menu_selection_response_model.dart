import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a menu selection response from Firestore
/// Used to store and retrieve guest's selected menu items
class MenuSelectionResponseModel {
  final String responseId;
  final String eventId;
  final String guestId;
  final String guestEmail;
  final String? guestName;
  final String invitationId;
  final List<String> selectedMenuItemIds;
  final DateTime createdAt;
  final bool isCompanion;
  final int? companionIndex;

  MenuSelectionResponseModel({
    required this.responseId,
    required this.eventId,
    required this.guestId,
    required this.guestEmail,
    this.guestName,
    required this.invitationId,
    required this.selectedMenuItemIds,
    required this.createdAt,
    this.isCompanion = false,
    this.companionIndex,
  });

  /// Create from Firestore document
  factory MenuSelectionResponseModel.fromFirestore(Map<String, dynamic> data) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return DateTime.now();
    }

    final itemIds = data['selectedMenuItemIds'] as List<dynamic>? ?? [];
    final selectedIds = itemIds.map((id) => id.toString()).toList();

    return MenuSelectionResponseModel(
      responseId: data['responseId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      guestId: data['guestId'] as String? ?? '',
      guestEmail: data['guestEmail'] as String? ?? '',
      guestName: data['guestName'] as String?,
      invitationId: data['invitationId'] as String? ?? '',
      selectedMenuItemIds: selectedIds,
      createdAt: parseTimestamp(data['createdAt']),
      isCompanion: data['isCompanion'] as bool? ?? false,
      companionIndex: data['companionIndex'] as int?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'guestId': guestId,
      'guestEmail': guestEmail,
      if (guestName != null) 'guestName': guestName,
      'invitationId': invitationId,
      'selectedMenuItemIds': selectedMenuItemIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompanion': isCompanion,
      if (companionIndex != null) 'companionIndex': companionIndex,
    };
  }

  /// Create a copy with updated fields
  MenuSelectionResponseModel copyWith({
    String? responseId,
    String? eventId,
    String? guestId,
    String? guestEmail,
    String? guestName,
    String? invitationId,
    List<String>? selectedMenuItemIds,
    DateTime? createdAt,
    bool? isCompanion,
    int? companionIndex,
  }) {
    return MenuSelectionResponseModel(
      responseId: responseId ?? this.responseId,
      eventId: eventId ?? this.eventId,
      guestId: guestId ?? this.guestId,
      guestEmail: guestEmail ?? this.guestEmail,
      guestName: guestName ?? this.guestName,
      invitationId: invitationId ?? this.invitationId,
      selectedMenuItemIds: selectedMenuItemIds ?? this.selectedMenuItemIds,
      createdAt: createdAt ?? this.createdAt,
      isCompanion: isCompanion ?? this.isCompanion,
      companionIndex: companionIndex ?? this.companionIndex,
    );
  }

  /// Get count of selected items
  int get selectedCount => selectedMenuItemIds.length;

  /// Check if any items are selected
  bool get hasSelections => selectedMenuItemIds.isNotEmpty;

  @override
  String toString() {
    return 'MenuSelectionResponseModel('
        'responseId: $responseId, '
        'eventId: $eventId, '
        'guestId: $guestId, '
        'guestEmail: $guestEmail, '
        'guestName: $guestName, '
        'invitationId: $invitationId, '
        'selectedMenuItemIds: ${selectedMenuItemIds.length} items, '
        'createdAt: $createdAt, '
        'isCompanion: $isCompanion, '
        'companionIndex: $companionIndex'
        ')';
  }
}
