import 'package:flutter/cupertino.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';

class GuestProfileFieldConfig {
  final TextEditingController fieldNameController = TextEditingController();
  final TextEditingController groupIdController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  InputType? inputType;
  int? id;
  final String? fieldName;
  final String? groupId;
  final String? answer;

  GuestProfileFieldConfig(
      {this.fieldName, this.groupId, this.inputType, this.answer, this.id}) {
    fieldNameController.text = fieldName ?? '';
    groupIdController.text = groupId ?? '';
    answerController.text = answer ?? '';
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
