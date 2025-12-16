// lib/utils/currency.dart
import 'package:intl/intl.dart';

class AppCurrency {
  // Use en_US for typical $ formatting. If you want different locale rules,
  // change the locale string accordingly.
  static final NumberFormat formatter =
      NumberFormat.currency(locale: 'en_US', symbol: '\$');

  // Convenience helper
  static String format(num? value) {
    if (value == null) return formatter.format(0);
    return formatter.format(value);
  }
}
