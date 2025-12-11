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

  /// Safely parse a DocumentSnapshot into a QuestionSet.
  /// Provides defensive defaults for any missing fields used by UI.
  factory QuestionSet.fromDoc(DocumentSnapshot<Object?> doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final id = doc.id;
    final questionSetId = (data['questionSetId'] as String?)?.trim() ?? id;
    final title = (data['title'] as String?)?.trim() ?? '(Untitled set)';
    final celebrationType = (data['celebrationType'] as String?)?.trim() ?? '';
    final description = (data['description'] as String?)?.trim() ?? '';
    final userId = (data['userId'] as String?)?.trim() ?? '';
    final isDisabled = data['isDisabled'] as bool? ?? false;
    final createdDate = (data['createdDate'] is Timestamp)
        ? (data['createdDate'] as Timestamp).toDate()
        : null;
    final modifiedDate = (data['modifiedDate'] is Timestamp)
        ? (data['modifiedDate'] as Timestamp).toDate()
        : null;

    return QuestionSet(
      id: id,
      questionSetId: questionSetId,
      title: title,
      celebrationType: celebrationType,
      description: description,
      userId: userId,
      isDisabled: isDisabled,
      createdDate: createdDate,
      modifiedDate: modifiedDate,
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
      'createdDate':
          createdDate != null ? Timestamp.fromDate(createdDate!) : null,
      'modifiedDate':
          modifiedDate != null ? Timestamp.fromDate(modifiedDate!) : null,
    }..removeWhere((k, v) => v == null);
  }
}
