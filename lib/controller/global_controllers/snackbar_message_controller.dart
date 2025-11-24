import 'package:get/get.dart';
import 'package:traxx_wepapp/models/snack_bar_message.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';

/// Global controller for handling snackbar messages across the app.
class SnackbarMessageController extends GetxController {
  final message = Rxn<SnackBarMessage>();

  /// Clears the current message
  void clearMessage() {
    message.value = null;
  }

  /// Shows a success message
  void showSuccessMessage(String text) {
    message.value = SnackBarMessage(
      message: text,
      type: SnackBarType.success,
    );
  }

  /// Shows an error message
  void showErrorMessage(String text) {
    message.value = SnackBarMessage(
      message: text,
      type: SnackBarType.error,
    );
  }
}
