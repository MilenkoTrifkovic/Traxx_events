import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a demographic response from Firestore
/// Used to store and retrieve guest's demographic answers
class DemographicResponseModel {
  final String responseId;
  final String eventId;
  final String guestId;
  final String guestEmail;
  final String? guestName;
  final String invitationId;
  final String? demographicQuestionSetId;
  final List<DemographicAnswer> answers;
  final DateTime createdAt;
  final bool isCompanion;
  final int? companionIndex;

  DemographicResponseModel({
    required this.responseId,
    required this.eventId,
    required this.guestId,
    required this.guestEmail,
    this.guestName,
    required this.invitationId,
    this.demographicQuestionSetId,
    required this.answers,
    required this.createdAt,
    this.isCompanion = false,
    this.companionIndex,
  });

  /// Create from Firestore document
  factory DemographicResponseModel.fromFirestore(Map<String, dynamic> data) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return DateTime.now();
    }

    final answersData = data['answers'] as List<dynamic>? ?? [];
    final answers = answersData
        .map((item) => DemographicAnswer.fromMap(item as Map<String, dynamic>))
        .toList();

    return DemographicResponseModel(
      responseId: data['responseId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      guestId: data['guestId'] as String? ?? '',
      guestEmail: data['guestEmail'] as String? ?? '',
      guestName: data['guestName'] as String?,
      invitationId: data['invitationId'] as String? ?? '',
      demographicQuestionSetId: data['demographicQuestionSetId'] as String?,
      answers: answers,
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
      if (demographicQuestionSetId != null)
        'demographicQuestionSetId': demographicQuestionSetId,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompanion': isCompanion,
      if (companionIndex != null) 'companionIndex': companionIndex,
    };
  }

  /// Create a copy with updated fields
  DemographicResponseModel copyWith({
    String? responseId,
    String? eventId,
    String? guestId,
    String? guestEmail,
    String? guestName,
    String? invitationId,
    String? demographicQuestionSetId,
    List<DemographicAnswer>? answers,
    DateTime? createdAt,
    bool? isCompanion,
    int? companionIndex,
  }) {
    return DemographicResponseModel(
      responseId: responseId ?? this.responseId,
      eventId: eventId ?? this.eventId,
      guestId: guestId ?? this.guestId,
      guestEmail: guestEmail ?? this.guestEmail,
      guestName: guestName ?? this.guestName,
      invitationId: invitationId ?? this.invitationId,
      demographicQuestionSetId:
          demographicQuestionSetId ?? this.demographicQuestionSetId,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      isCompanion: isCompanion ?? this.isCompanion,
      companionIndex: companionIndex ?? this.companionIndex,
    );
  }

  @override
  String toString() {
    return 'DemographicResponseModel('
        'responseId: $responseId, '
        'eventId: $eventId, '
        'guestId: $guestId, '
        'guestEmail: $guestEmail, '
        'guestName: $guestName, '
        'invitationId: $invitationId, '
        'answers: ${answers.length}, '
        'createdAt: $createdAt, '
        'isCompanion: $isCompanion, '
        'companionIndex: $companionIndex'
        ')';
  }
}

/// Model representing a single demographic answer
class DemographicAnswer {
  final String questionId;
  final String questionText;
  final String type;
  final bool isRequired;
  final dynamic answer; // Can be String, List, Map, etc.

  DemographicAnswer({
    required this.questionId,
    required this.questionText,
    required this.type,
    required this.isRequired,
    required this.answer,
  });

  /// Create from Map
  factory DemographicAnswer.fromMap(Map<String, dynamic> map) {
    return DemographicAnswer(
      questionId: map['questionId'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      type: map['type'] as String? ?? '',
      isRequired: map['isRequired'] as bool? ?? false,
      answer: map['answer'],
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'type': type,
      'isRequired': isRequired,
      'answer': answer,
    };
  }

  /// Get formatted answer as string for display
  String getFormattedAnswer() {
    if (answer == null) return 'Not answered';

    if (type == 'short_answer' || type == 'paragraph') {
      return answer.toString();
    }

    if (type == 'multiple_choice' || type == 'dropdown') {
      if (answer is Map) {
        return answer['text']?.toString() ?? 'Selected';
      }
      return answer.toString();
    }

    if (type == 'checkboxes') {
      if (answer is List) {
        final items = answer
            .map((item) => item is Map ? item['text']?.toString() : item.toString())
            .where((text) => text != null && text.isNotEmpty)
            .join(', ');
        return items.isNotEmpty ? items : 'No items selected';
      }
    }

    return answer.toString();
  }

  @override
  String toString() {
    return 'DemographicAnswer('
        'questionId: $questionId, '
        'questionText: $questionText, '
        'type: $type, '
        'isRequired: $isRequired, '
        'answer: $answer'
        ')';
  }
}
