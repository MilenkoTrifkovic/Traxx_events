import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:traxx_wepapp/utils/enums/event_type.dart';

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
    required ServiceType? serviceType,
    required DateTime? date,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required DateTime? rsvpDeadline,
    required String? eventType,
    required String? timezone,
    required dynamic location,
  }) {
    if (name.isEmpty) {
      throw EventValidationException('Event name is required');
    }
    if (address.isEmpty) {
      throw EventValidationException('Event address is required');
    }
    if (date == null) {
      throw EventValidationException('Event date is required');
    }
    if (startTime == null) {
      throw EventValidationException('Start time is required');
    }
    // ServiceType is now optional - no validation needed
    if (endTime == null) {
      throw EventValidationException('End time is required');
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
    // Location is now optional - no validation needed

    final capacityNum = int.tryParse(capacity);
    if (capacityNum == null) {
      throw EventValidationException('Valid capacity number is required');
    }

    // Create DateTime objects for comparison
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      throw EventValidationException('End time must be after start time');
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
