import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestResponse {
  String? guestId;
  String? guestName;
  bool isAttending;
  final List<EventQuestions> questionAnswers;
  final Map<String, String> menus =
      {}; // menu category and selected menu item id
  final String? inviterId;
  final DateTime? createdAt;

  bool
      isExpanded; //this is used only for UI for Expansion Panel List. It Shouldn't be stored anywhere...

  GuestResponse({
    this.guestId,
    this.guestName,
    this.isAttending = false,
    this.inviterId,
    this.questionAnswers = const [],
    this.createdAt,
    this.isExpanded = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'guestId': guestId,
      'guestName': guestName,
      'isAttending': isAttending,
      'inviterId': inviterId,
      'menus': menus,
      'questionAnswers':
          questionAnswers.map((q) => q.toJson(includeAnswer: true)).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create GuestResponse from Firestore document
  factory GuestResponse.fromFirestore(Map<String, dynamic> doc) {
    final response = GuestResponse(
      guestId: doc['guestId'] as String?,
      guestName: doc['guestName'] as String?,
      isAttending: doc['isAttending'] as bool? ?? false,
      inviterId: doc['inviterId'] as String?,
      questionAnswers: (doc['questionAnswers'] as List<dynamic>?)
              ?.map((q) => EventQuestions(
                    fieldName: q['fieldName'] as String?,
                    groupId: q['groupId'] as String?,
                    answer: q['answer'] as String?,
                  ))
              .toList() ??
          [],
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate(),
    );

    // Add menus if they exist
    if (doc['menus'] != null) {
      response.menus.addAll(Map<String, String>.from(doc['menus'] as Map));
    }

    return response;
  }

  @override
  String toString() {
    return 'GuestResponse(guestId: $guestId, guestName: $guestName, isAttending: $isAttending, inviterId: $inviterId, menus: $menus, questionAnswers: $questionAnswers, createdAt: $createdAt)';
  }
}
