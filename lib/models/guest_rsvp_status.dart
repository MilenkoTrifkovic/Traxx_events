class GuestRsvpStatus {
  final bool hasResponded;
  final bool? isAttending;
  final DateTime? updatedAt;

  const GuestRsvpStatus({
    required this.hasResponded,
    required this.isAttending,
    required this.updatedAt,
  });
}
