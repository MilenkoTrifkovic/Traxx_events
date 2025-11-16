class ValidationHelper {
  static String? validateWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL (e.g., https://example.com)';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Location & Time Form Validations
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 5) {
      return 'Please enter a complete address';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    if (value.length < 2) {
      return 'Please enter a valid city name';
    }
    // Check if contains only letters, spaces, hyphens, and apostrophes
    final cityRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!cityRegex.hasMatch(value)) {
      return 'City name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Zip code is required';
    }
    // US zip code format: 12345 or 12345-6789
    final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
    if (!zipRegex.hasMatch(value)) {
      return 'Enter a valid US zip code (e.g., 12345 or 12345-6789)';
    }
    return null;
  }

  static String? validateDropdownSelection(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }

  // Restaurant Info Form Validations
  static String? validateCompanyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Company name is required';
    }
    if (value.length < 2) {
      return 'Company name must be at least 2 characters long';
    }
    if (value.length > 100) {
      return 'Company name cannot exceed 100 characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // 1) Keep only digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // 2) If there are 11 digits and it starts with 1 (US country code), remove the first digit
    String normalized = digitsOnly;
    if (normalized.length == 11 && normalized.startsWith('1')) {
      normalized = normalized.substring(1);
    }

    // 3) Now we expect exactly 10 digits
    if (normalized.length != 10) {
      return 'Please enter a valid US phone number';
    }

    return null;
  }

  static String? validateOptionalWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Remove https:// prefix if present for validation
    String urlToValidate = value;
    if (value.startsWith('https://')) {
      urlToValidate = value.substring(8);
    }

    // Basic website validation
    final websiteRegex = RegExp(
        r'^(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');

    if (!websiteRegex.hasMatch(urlToValidate)) {
      return 'Enter a valid website URL (e.g., example.com)';
    }

    return null;
  }

  // Form-level validations
  static bool isLocationFormValid({
    required String? address,
    required String? city,
    required String? country,
    required String? state,
    required String? zipCode,
    required String? timezone,
  }) {
    return validateAddress(address) == null &&
        validateCity(city) == null &&
        validateDropdownSelection(country, 'country') == null &&
        validateDropdownSelection(state, 'state') == null &&
        validateZipCode(zipCode) == null &&
        validateDropdownSelection(timezone, 'timezone') == null;
  }

  static bool isRestaurantInfoFormValid({
    required String? companyName,
    required String? phoneNumber,
    String? website,
  }) {
    return validateCompanyName(companyName) == null &&
        validatePhoneNumber(phoneNumber) == null &&
        validateOptionalWebsite(website) == null;
  }
}
