import 'package:flutter/material.dart';

/// Enum representing the possible states of an event
enum EventStatus {
  /// Event is saved but not published yet
  draft,

  /// Event is published and visible to guests
  published,

  /// Event is published and accepting RSVPs
  live,

  /// Event is scheduled for the future
  upcoming,

  /// Event has finished
  completed,
}

/// Extension to provide display names and utility methods for EventStatus
extension EventStatusExtension on EventStatus {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.published:
        return 'Published';
      case EventStatus.live:
        return 'Live';
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.completed:
        return 'Completed';
    }
  }

  /// Get the color associated with this status
  Color get color {
    switch (this) {
      case EventStatus.draft:
        return Colors.grey;
      case EventStatus.published:
        return Colors.teal;
      case EventStatus.live:
        return Colors.green;
      case EventStatus.upcoming:
        return Colors.blue;
      case EventStatus.completed:
        return Colors.orange;
    }
  }

  /// Get the status name for storage
  String get statusName => name;

  /// Create EventStatus from string name
  static EventStatus fromString(String statusName) {
    return EventStatus.values.firstWhere(
      (status) => status.name == statusName,
      orElse: () => EventStatus.draft,
    );
  }
}
