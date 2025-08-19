class EventValidationException implements Exception {
  final String message;
  EventValidationException(this.message);

  @override
  String toString() => message;
}

class EventValidator {
  static void validateRequiredFields({
    required String name,
    required String address,
    required String capacity,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
    required DateTime? rsvpDeadline,
    required String? eventType,
    required String? timezone,
    required dynamic location,
    required dynamic coverImage,
  }) {
    if (name.isEmpty) {
      throw EventValidationException('Event name is required');
    }
    if (address.isEmpty) {
      throw EventValidationException('Event address is required');
    }
    if (startDateTime == null) {
      throw EventValidationException('Start date and time is required');
    }
    if (endDateTime == null) {
      throw EventValidationException('End date and time is required');
    }
    if (rsvpDeadline == null) {
      throw EventValidationException('RSVP deadline is required');
    }
    if (eventType == null) {
      throw EventValidationException('Event type is required');
    }
    if (timezone == null) {
      throw EventValidationException('Timezone is required');
    }
    if (location == null) {
      throw EventValidationException('Location is required');
    }

    final capacityNum = int.tryParse(capacity);
    if (capacityNum == null) {
      throw EventValidationException('Valid capacity number is required');
    }

    if (endDateTime.isBefore(startDateTime)) {
      throw EventValidationException('End date must be after start date');
    }
    if (rsvpDeadline.isAfter(startDateTime)) {
      throw EventValidationException(
          'RSVP deadline must be before event start');
    }
    if (capacityNum <= 0) {
      throw EventValidationException('Capacity must be greater than 0');
    }
  }
}
