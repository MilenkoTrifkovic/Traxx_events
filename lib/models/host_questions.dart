import 'package:cloud_firestore/cloud_firestore.dart';

class DemographicQuestion {
  final String id; // Firestore doc id
  final String questionId;
  final String questionSetId;
  final String questionText;
  final String questionType;
  final String userId;
  final int displayOrder;
  final bool isRequired;
  final bool isDisabled;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final String? parentQuestionId;
  final String? triggerOptionId;

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
    this.parentQuestionId,
    this.triggerOptionId,
  });

  factory DemographicQuestion.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final parent = (data['parentQuestionId'] ?? '').toString().trim();
    final trigger = (data['triggerOptionId'] ?? '').toString().trim();
    return DemographicQuestion(
      id: doc.id,
      questionId: data['questionId'] as String? ?? doc.id,
      questionSetId: data['questionSetId'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      questionType: data['questionType'] as String? ?? 'text',
      userId: data['userId'] as String? ?? '',
      displayOrder: (data['displayOrder'] is num)
          ? (data['displayOrder'] as num).toInt()
          : int.tryParse('${data['displayOrder']}') ?? 0,
      isRequired: data['isRequired'] as bool? ?? false,
      isDisabled: data['isDisabled'] as bool? ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
      modifiedDate: (data['modifiedDate'] as Timestamp?)?.toDate(),
      parentQuestionId: parent.isEmpty ? null : parent,
      triggerOptionId: trigger.isEmpty ? null : trigger,
    );
  }
}
