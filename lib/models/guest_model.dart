import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

/// Guest model for event attendees.
///
/// Required fields:
/// - `name` (required)
/// - `email` (required)
/// - `eventId` (required) : event this guest belongs to
///
/// Optional fields:
/// - `address` (optional)
/// - `city` (optional)
/// - `state` (optional)
/// - `country` (optional)
/// - `gender` (optional)
///
/// General fields (inherited from pattern):
/// - `guestId` (optional) : logical guest id
/// - `createdAt` (auto)
/// - `modifiedAt` (auto)
/// - `isDisabled` (default false)
class GuestModel {
  final String? guestId;
  final String name;
  final String email;
  final String eventId;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  // final String? gender;
  final Gender? gender;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;
  final bool isInvited;

  GuestModel({
    this.guestId,
    required this.name,
    required this.email,
    required this.eventId,
    this.address,
    this.city,
    this.state,
    this.country,
    this.gender,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    this.isInvited = false,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      if (guestId != null) 'guestId': guestId,
      'name': name,
      'email': email,
      'eventId': eventId,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender!.name, // Store enum name as string
      'isDisabled': isDisabled,
      'isInvited': isInvited,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      if (guestId != null) 'guestId': guestId,
      'name': name,
      'email': email,
      'eventId': eventId,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender!.name, // Store enum name as string
      'isDisabled': isDisabled,
      'isInvited': isInvited,
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory GuestModel.fromFirestore(Map<String, dynamic> data, [String? id]) {
    Gender? parseGender(dynamic genderData) {
      if (genderData == null) return null;

      if (genderData is Gender) return genderData;

      if (genderData is String && genderData.isNotEmpty) {
        final lower = genderData.toLowerCase();
        // Try match by enum name
        try {
          return Gender.values.firstWhere((g) => g.name.toLowerCase() == lower,
              orElse: () {
            // fallback mapping for common variants
            if (lower == 'm' || lower == 'male') return Gender.male;
            if (lower == 'f' || lower == 'female') return Gender.female;
            if (lower.contains('prefer') || lower.contains('not')) {
              return Gender.preferNotToSay;
            }
            return Gender.preferNotToSay;
          });
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DateTime? parseTimestamp(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate();
      if (t is DateTime) return t;
      return null;
    }

    // Prefer doc id (id param) if provided, otherwise fall back to guestId field in document
    final resolvedGuestId = (id != null && id.isNotEmpty)
        ? id
        : (data['guestId'] as String?)?.isNotEmpty == true
            ? data['guestId'] as String?
            : null;

    return GuestModel(
      guestId: resolvedGuestId,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      gender: parseGender(data['gender']),
      createdAt: parseTimestamp(data['createdAt']),
      modifiedAt: parseTimestamp(data['modifiedAt']),
      isDisabled: data['isDisabled'] as bool? ?? false,
      isInvited: data['isInvited'] as bool? ?? false,
    );
  }

  GuestModel copyWith({
    String? guestId,
    String? name,
    String? email,
    String? eventId,
    String? address,
    String? city,
    String? state,
    String? country,
    // String? gender,
    Gender? gender,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
    bool? isInvited,
  }) {
    return GuestModel(
      guestId: guestId ?? this.guestId,
      name: name ?? this.name,
      email: email ?? this.email,
      eventId: eventId ?? this.eventId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
      isInvited: isInvited ?? this.isInvited,
    );
  }

  @override
  String toString() {
    return 'GuestModel('
        'guestId: $guestId, '
        'name: $name, '
        'email: $email, '
        'eventId: $eventId, '
        'address: $address, '
        'city: $city, '
        'state: $state, '
        'country: $country, '
        'gender: ${gender?.name}, '
        'createdAt: $createdAt, '
        'modifiedAt: $modifiedAt, '
        'isDisabled: $isDisabled, '
        'isInvited: $isInvited'
        ')';
  }
}
