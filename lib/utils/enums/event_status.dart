/// Enum representing the possible states of an event
enum EventStatus {
  /// Event is saved but not published yet
  draft,

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
      case EventStatus.live:
        return 'Live';
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.completed:
        return 'Completed';
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
