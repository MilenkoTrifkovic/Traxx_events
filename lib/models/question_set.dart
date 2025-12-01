// lib/models/question_set.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionSet {
  final String id; // Firestore doc id
  final String questionSetId; // explicit field in Firestore (duplicate of id)
  final String title;
  final String celebrationType;
  final String description; // short description
  final String userId;
  final bool isDisabled;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  QuestionSet({
    required this.id,
    required this.questionSetId,
    required this.title,
    required this.celebrationType,
    required this.description,
    required this.userId,
    required this.isDisabled,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory QuestionSet.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return QuestionSet(
      id: doc.id,
      questionSetId: data['questionSetId'] as String? ?? doc.id, // 👈 NEW
      title: data['title'] as String? ?? '',
      celebrationType: data['celebrationType'] as String? ?? '',
      description: data['description'] as String? ?? '', // 👈 NEW
      userId: data['userId'] as String? ?? '',
      isDisabled: data['isDisabled'] as bool? ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
      modifiedDate: (data['modifiedDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionSetId': questionSetId,
      'title': title,
      'celebrationType': celebrationType,
      'description': description,
      'userId': userId,
      'isDisabled': isDisabled,
      'createdDate': createdDate,
      'modifiedDate': modifiedDate,
    };
  }
}
