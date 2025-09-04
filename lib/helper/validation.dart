/// Helper class providing validation methods for various input types.
class Validation {
  /// Validates an email address.
  ///
  /// Returns null if email is valid, otherwise returns an error message.
  /// The email must:
  /// - Not be empty
  /// - Match basic email format (username@domain.tld)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }

    // Basic email regex that covers most common cases
    final emailRegExp = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }
}
