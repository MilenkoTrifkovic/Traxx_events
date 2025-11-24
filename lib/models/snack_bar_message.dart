import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';

/// Model for snackbar messages
class SnackBarMessage {
  final String message;
  final SnackBarType type;

  SnackBarMessage({
    required this.message,
    required this.type,
  });
}
