// lib/models/demographic_question_option.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/host_questions.dart';

class DemographicQuestionOption {
  final String id; // Firestore doc id
  final String questionId;
  final String label;
  final String value;
  final String optionType; // e.g. choice, other_with_text
  final bool requiresFreeText;
  final bool isDisabled;
  final int displayOrder;

  DemographicQuestionOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.value,
    required this.optionType,
    required this.requiresFreeText,
    required this.isDisabled,
    required this.displayOrder,
  });

  factory DemographicQuestionOption.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return DemographicQuestionOption(
      id: doc.id,
      questionId: data['questionId'] as String? ?? '',
      label: data['label'] as String? ?? '',
      value: data['value'] as String? ?? '',
      optionType: data['optionType'] as String? ?? 'choice',
      requiresFreeText: data['requiresFreeText'] as bool? ?? false,
      isDisabled: data['isDisabled'] as bool? ?? false,
      displayOrder: (data['displayOrder'] ?? 0) as int,
    );
  }
}

/// Convenience combined model (Question + its options)
class DemographicQuestionWithOptions {
  final DemographicQuestion question;
  final List<DemographicQuestionOption> options;

  DemographicQuestionWithOptions({
    required this.question,
    required this.options,
  });
}
