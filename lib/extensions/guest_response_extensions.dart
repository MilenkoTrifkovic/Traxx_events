import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu.dart';

extension GuestResponseTable on GuestResponse {
  /// Converts the guest response into a flat map structure for table display.
  /// Each field becomes a separate column in the resulting data structure.
  Map<String, String> toTableRow(List<MenuItem> allMenuItems) {
    final Map<String, String> row = {
      'Guest Name': guestName ?? 'You',
    };

    // Add each question as a separate column

    // Add each menu selection as a separate column
    menus.forEach((category, menuItemId) {
      // row[category] = menuItemId;
      row[category] = allMenuItems
          .firstWhere((element) => element.id == menuItemId)
          .dishName;
    });

    for (final question in questionAnswers) {
      if (question.fieldName != null) {
        row[question.fieldName!] = question.answerController.text.trim();
      }
    }
    // Add metadata

    return row;
  }
}
