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
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory GuestModel.fromFirestore(Map<String, dynamic> data, [String? id]) {
    Gender? parseGender(dynamic genderData) {
      if (genderData == null) return null;

      if (genderData is Gender) {
        return genderData;
      } else if (genderData is String) {
        // Try to find matching enum by name
        try {
          return Gender.values.firstWhere(
            (g) => g.name.toLowerCase() == genderData.toLowerCase(),
            orElse: () => Gender.values.firstWhere(
              (g) =>
                  g.toString().split('.').last.toLowerCase() ==
                  genderData.toLowerCase(),
              orElse: () => Gender.preferNotToSay,
            ),
          );
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return GuestModel(
      guestId: data['guestId'] as String?,
      name: data['name'] as String,
      email: data['email'] as String,
      eventId: data['eventId'] as String,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      gender: parseGender(data['gender']),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      modifiedAt: (data['modifiedAt'] is Timestamp)
          ? (data['modifiedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
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
        'isDisabled: $isDisabled'
        ')';
  }
}
