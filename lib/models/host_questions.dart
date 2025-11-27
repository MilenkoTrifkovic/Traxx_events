import 'package:cloud_firestore/cloud_firestore.dart';

class DemographicQuestion {
  final String id; // Firestore doc id
  final String questionId;
  final String questionSetId; // NEW – link to the set
  final String questionText;
  final String questionType; // e.g. 'multiple_choice', 'short_answer'
  final String userId;
  final int displayOrder;
  final bool isRequired;
  final bool isDisabled;
  final DateTime? createdDate;
  final DateTime? modifiedDate;

  DemographicQuestion({
    required this.id,
    required this.questionId,
    required this.questionSetId,
    required this.questionText,
    required this.questionType,
    required this.userId,
    required this.displayOrder,
    required this.isRequired,
    required this.isDisabled,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory DemographicQuestion.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DemographicQuestion(
      id: doc.id,
      questionId: data['questionId'] as String? ?? doc.id,
      questionSetId: data['questionSetId'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      questionType: data['questionType'] as String? ?? 'text',
      userId: data['userId'] as String? ?? '',
      displayOrder: (data['displayOrder'] ?? 0) as int,
      isRequired: data['isRequired'] as bool? ?? false,
      isDisabled: data['isDisabled'] as bool? ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
      modifiedDate: (data['modifiedDate'] as Timestamp?)?.toDate(),
    );
  }
}
