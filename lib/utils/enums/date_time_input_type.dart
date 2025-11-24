/// Enum for DateTime input field selection types
enum DateTimeInputType {
  /// Select both date and time
  dateTime,

  /// Select only date
  dateOnly,

  /// Select only time
  timeOnly,
}

/// Extension to provide display names for DateTimeInputType
extension DateTimeInputTypeExtension on DateTimeInputType {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case DateTimeInputType.dateTime:
        return 'Date & Time';
      case DateTimeInputType.dateOnly:
        return 'Date';
      case DateTimeInputType.timeOnly:
        return 'Time';
    }
  }

  /// Get the appropriate icon for the input type
  String get iconPath {
    switch (this) {
      case DateTimeInputType.dateTime:
        return 'assets/icons/calendar-solid.svg';
      case DateTimeInputType.dateOnly:
        return 'assets/icons/calendar-solid.svg';
      case DateTimeInputType.timeOnly:
        return 'assets/icons/calendar-solid.svg'; // Using calendar for time until clock icon is available
    }
  }

  /// Get the hint text for the input type
  String get hintText {
    switch (this) {
      case DateTimeInputType.dateTime:
        return 'Select date and time';
      case DateTimeInputType.dateOnly:
        return 'Select date';
      case DateTimeInputType.timeOnly:
        return 'Select time';
    }
  }
}
