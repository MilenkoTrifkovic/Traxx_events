import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';

/// A row of action buttons (Save and Cancel)
///
/// Typically used at the bottom of forms or dialogs
class ActionButtons extends StatelessWidget {
  /// Callback function when save button is pressed
  final VoidCallback onSave;

  /// Callback function when update button is pressed
  final VoidCallback onUpdate;

  /// Callback function when cancel button is pressed
  final VoidCallback onCancel;

  const ActionButtons(
      {super.key,
      required this.onSave,
      required this.onCancel,
      required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    HostController hostController = Get.find<HostController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        StyledTextButton(
          onPressed: onCancel,
          text: 'Cancel',
          isPrimary: false,
        ),
        const SizedBox(width: 16),
        StyledTextButton(
          onPressed: hostController.isEditingEvent.value ? onUpdate : onSave,
          text: hostController.isEditingEvent.value ? 'Update' : 'Save',
          isPrimary: true,
        ),
      ],
    );
  }
}
