import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_buttons.dart';

/// A row of action buttons (Save and Cancel)
///
/// Typically used at the bottom of forms or dialogs
class ActionButtons extends StatelessWidget {
  /// Callback function when save button is pressed
  final VoidCallback onSave;

  /// Callback function when cancel button is pressed
  final VoidCallback onCancel;

  const ActionButtons(
      {super.key, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
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
          onPressed: onSave,
          text: 'Save',
          isPrimary: true,
        ),
      ],
    );
  }
}
