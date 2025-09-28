import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';

/// A form widget that handles various types of event questions and responses.
///
/// This widget supports different input types (text, number, date, yes/no) and provides
/// appropriate validation for each. It uses a [GlobalKey<FormState>] to manage form validation
/// and registers the validation function with its parent widget.
///
/// The form automatically builds appropriate input fields based on the [InputType]
/// of each question in the [GuestResponse].
class ResponseForm extends StatefulWidget {
  /// Callback to register the form's validation function with the parent widget.
  /// The parent can then trigger validation when needed (e.g., on submit).
  final Function(Function) registerValidation;

  /// Contains the guest's response data including questions, answers...
  final GuestResponse guestResponse;

  const ResponseForm({
    super.key,
    required this.guestResponse,
    required this.registerValidation,
  });

  @override
  State<ResponseForm> createState() => _ResponseFormState();
}

class _ResponseFormState extends State<ResponseForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.registerValidation(() => formKey.currentState!.validate());
  }

  /// Builds an appropriate form field based on the question's input type.
  ///
  /// Supports:
  /// * [InputType.text] - Basic text input with required validation
  /// * [InputType.number] - Numeric input with number validation
  /// * [InputType.date] - Date picker with date range validation
  /// * [InputType.yesno] - Dropdown with Yes/No options
  Widget _buildFormField(EventQuestions question) {
    switch (question.inputType) {
      case InputType.text:
        return TextFormField(
          controller: question.answerController,
          decoration: InputDecoration(
            labelText: question.fieldName,
            border: const OutlineInputBorder(),
          ),
          // validator: (value) {
          //   if (value == null || value.isEmpty) {
          //     return 'Please enter ${question.fieldName}';
          //   }
          //   return null;
          // },
        );

      case InputType.number:
        return TextFormField(
          controller: question.answerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: question.fieldName,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a number';
            }
            if (!GetUtils.isNum(value)) {
              return 'Please enter a valid number';
            }
            return null;
          },
        );

      case InputType.date:
        return TextFormField(
          controller: question.answerController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: question.fieldName,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select ${question.fieldName}';
            }
            try {
              final date = DateTime.parse(value);
              if (date.isAfter(DateTime(2100)) ||
                  date.isBefore(DateTime(1900))) {
                return 'Please select a valid date between 1900 and 2100';
              }
            } catch (e) {
              return 'Invalid date format';
            }
            return null;
          },
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              question.answerController.text = date.toString().split(' ')[0];
            }
          },
        );

      case InputType.yesno:
        return DropdownButtonFormField<String>(
          value: question.answerController.text.isEmpty
              ? null
              : question.answerController.text,
          hint: AppText.styledBodyMedium(context, 'Select an option'),
          decoration: InputDecoration(
            labelText: question.fieldName,
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an option';
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) {
              question.answerController.text = value;
            }
          },
        );

      default:
        return TextFormField(
          controller: question.answerController,
          decoration: InputDecoration(
            labelText: question.fieldName,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.guestResponse.questionAnswers;
    if (questions.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        AppSpacing.verticalMd(context),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer,
              color: AppColors.primary(context),
            ),
            AppSpacing.horizontalSm(context),
            Flexible(
              child: AppText.styledBodyMedium(context, 'Additional Questions',
                  weight: FontWeight.bold, textAlign: TextAlign.center),
            ),
            AppSpacing.horizontalSm(context),
            Icon(
              Icons.question_answer,
              color: AppColors.primary(context),
            )
          ],
        ),
        AppSpacing.verticalXs(context),
        //FORM
        Form(
            key: formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.guestResponse.guestId == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      print('Guest name updated: $value');
                      widget.guestResponse.guestName = value;
                    },
                  ),
                ),
              ...questions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.styledBodyMedium(
                        context,
                        question.fieldName ?? '',
                        weight: FontWeight.bold,
                      ),
                      AppSpacing.verticalXs(context),
                      _buildFormField(question),
                    ],
                  ),
                );
              }),
            ])),
      ],
    );
  }
}
