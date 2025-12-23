import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

class GuestModel {
  /// Firestore document id (optional for “draft” guests parsed from files)
  final String docId;

  /// Your business id field (you currently set it = doc id)
  final String? guestId;

  final String name;
  final String email;
  final String eventId;

  final String? address;
  final String? city;
  final String? state;
  final String? country;

  final Gender? gender;

  final DateTime? createdAt;
  final DateTime? modifiedAt;

  final bool isDisabled;
  final bool isInvited;
  final int maxGuestInvite;

  GuestModel({
    this.docId = '', // ✅ default, so parsers don’t need to pass it
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
    this.maxGuestInvite = 0,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      // ✅ Only store docId if you really want it (optional). Remove if you don’t want redundancy.
      if (docId.isNotEmpty) 'docId': docId,

      if (guestId != null && guestId!.trim().isNotEmpty) 'guestId': guestId,
      'name': name,
      'email': email,
      'eventId': eventId,

      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender!.name,

      'isDisabled': isDisabled,
      'isInvited': isInvited,
      'maxGuestInvite': maxGuestInvite,

      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      if (docId.isNotEmpty) 'docId': docId,
      if (guestId != null && guestId!.trim().isNotEmpty) 'guestId': guestId,
      'name': name,
      'email': email,
      'eventId': eventId,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender!.name,
      'isDisabled': isDisabled,
      'isInvited': isInvited,
      'maxGuestInvite': maxGuestInvite,
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory GuestModel.fromFirestore(Map<String, dynamic> data, [String? id]) {
    DateTime? parseTimestamp(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate();
      if (t is DateTime) return t;
      return null;
    }

    Gender? parseGender(dynamic genderData) {
      if (genderData == null) return null;
      if (genderData is Gender) return genderData;

      if (genderData is String && genderData.trim().isNotEmpty) {
        final lower = genderData.trim().toLowerCase();

        for (final g in Gender.values) {
          if (g.name.toLowerCase() == lower) return g;
        }

        if (lower == 'm' || lower == 'male') return Gender.male;
        if (lower == 'f' || lower == 'female') return Gender.female;
        if (lower.contains('prefer') ||
            lower.contains('not') ||
            lower == 'other') {
          return Gender.preferNotToSay;
        }
      }
      return null;
    }

    // ✅ docId resolution: prefer Firestore doc id param, then stored docId, then fallback to guestId
    final resolvedDocId = (id?.trim().isNotEmpty == true)
        ? id!.trim()
        : (data['docId']?.toString().trim().isNotEmpty == true)
            ? data['docId'].toString().trim()
            : (data['guestId']?.toString().trim().isNotEmpty == true)
                ? data['guestId'].toString().trim()
                : '';

    final guestIdField = (data['guestId']?.toString().trim().isNotEmpty == true)
        ? data['guestId'].toString().trim()
        : null;

    return GuestModel(
      docId: resolvedDocId,
      guestId: guestIdField,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      eventId: (data['eventId'] as String?) ?? '',
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      gender: parseGender(data['gender']),
      createdAt: parseTimestamp(data['createdAt']),
      modifiedAt: parseTimestamp(data['modifiedAt']),
      isDisabled: data['isDisabled'] as bool? ?? false,
      isInvited: data['isInvited'] as bool? ?? false,
      maxGuestInvite: data['maxGuestInvite'] as int? ?? 0,
    );
  }

  GuestModel copyWith({
    String? docId,
    String? guestId,
    String? name,
    String? email,
    String? eventId,
    String? address,
    String? city,
    String? state,
    String? country,
    Gender? gender,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
    bool? isInvited,
    int? maxGuestInvite,
  }) {
    return GuestModel(
      docId: docId ?? this.docId,
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
      maxGuestInvite: maxGuestInvite ?? this.maxGuestInvite,
    );
  }

  @override
  String toString() {
    return 'GuestModel('
        'docId: $docId, '
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
        'isInvited: $isInvited, '
        'maxGuestInvite: $maxGuestInvite'
        ')';
  }
}
