import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionSet {
  final String id; // Firestore doc id
  final String title; // e.g. "Food preferences for wedding"
  final String celebrationType; // e.g. "Wedding", "Birthday"
  final String userId;
  final bool isDisabled;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  QuestionSet({
    required this.id,
    required this.title,
    required this.celebrationType,
    required this.userId,
    required this.isDisabled,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory QuestionSet.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestionSet(
      id: doc.id,
      title: data['title'] as String? ?? '',
      celebrationType: data['celebrationType'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      isDisabled: data['isDisabled'] as bool? ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
      modifiedDate: (data['modifiedDate'] as Timestamp?)?.toDate(),
    );
  }
}
