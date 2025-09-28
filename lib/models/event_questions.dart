import 'package:flutter/cupertino.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';

class EventQuestions {
  final TextEditingController fieldNameController = TextEditingController();
  final TextEditingController groupIdController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  InputType? inputType;
  int? id;
  final String? fieldName;
  final String? groupId;
  final String? answer;

  EventQuestions(
      {this.fieldName, this.groupId, this.inputType, this.answer, this.id}) {
    fieldNameController.text = fieldName ?? '';
    groupIdController.text = groupId ?? '';
    answerController.text = answer ?? '';
  }
  factory EventQuestions.copyFrom(EventQuestions other) {
    return EventQuestions(
      fieldName: other.fieldName,
      groupId: other.groupId,
      inputType: other.inputType,
      answer: other.answer,
      id: other.id,
    )
      ..fieldNameController.text = other.fieldNameController.text
      ..groupIdController.text = other.groupIdController.text
      ..answerController.text = other.answerController.text;
  }
  Map<String, dynamic> toJson({bool includeAnswer = false}) {
    return {
      'fieldName': fieldNameController.text,
      'groupId': groupIdController.text,
      'inputType': inputType!.name,
      if (includeAnswer) 'answer': answerController.text.trim(),
    };
  }

  void changeInputType(InputType newInputType) {
    inputType = newInputType;
  }

  void disposeGuestProfileFieldConfigControllers() {
    fieldNameController.dispose();
    groupIdController.dispose();
    answerController.dispose();
  }

  @override
  String toString() {
    return 'GuestProfileFieldConfig(fieldName: $fieldName, groupId: $groupId, inputType: $inputType, id: $id, answer: $answer)';
  }
}
