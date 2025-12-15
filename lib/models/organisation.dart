import 'package:cloud_firestore/cloud_firestore.dart';

class Organisation {
  final String?
      organisationId; // Assigned by cloud function, empty when creating
  final String name; // Required
  final String phone; // Required
  final String? website; // Optional

  // Address fields - Required as a complete map
  final String street; // address.street
  final String city; // address.city
  final String zip; // address.zip
  final String state; // address.state
  final String country; // address.country

  final String timezone; // Required
  final String? logo; // Optional logo URL/path
  final String? photoUrl; // Local-only photo preview URL (not persisted)

  // Database fields
  final DateTime? createdAt;
  final DateTime? modifiedDate;
  final bool isDisabled;

  Organisation({
    this.organisationId, // Optional - assigned by cloud function
    required this.name,
    required this.phone,
    this.website,
    required this.street,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
    required this.timezone,
    this.logo,
    this.photoUrl,
    this.createdAt,
    this.modifiedDate,
    this.isDisabled = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'organisationId': organisationId,
      'name': name,
      'phone': phone,
      'website': website,
      'timezone': timezone,
      'logo': logo,
      'address': {
        'street': street,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
      },
      // 'createdAt': createdAt?.toIso8601String(),
      // 'modifiedDate': modifiedDate?.toIso8601String(),
      'isDisabled': isDisabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'modifiedDate': modifiedDate != null
          ? Timestamp.fromDate(modifiedDate!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Create Organisation from Firestore document
  factory Organisation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>? ?? {};

    return Organisation(
      organisationId: doc.id, // Get organisationId from document snapshot
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '', // Required field with fallback
      website: data['website'] as String?,
      timezone: data['timezone'] as String? ??
          'America/Los_Angeles (Pacific Time)', // Required with fallback
      logo: (data['logo'] as String?)?.trim(),
      street: address['street'] as String? ?? '',
      city: address['city'] as String? ?? '',
      state: address['state'] as String? ?? '',
      zip: address['zip'] as String? ?? '',
      country: address['country'] as String? ?? '',
      isDisabled: data['isDisabled'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      modifiedDate: (data['modifiedDate'] as Timestamp?)?.toDate(),
    );
  }

  // Create Organisation from JSON
  factory Organisation.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    return Organisation(
      organisationId: json['organisationId'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '', // Required field with fallback
      website: json['website'] as String?,
      timezone: json['timezone'] as String? ??
          'America/Los_Angeles (Pacific Time)', // Required with fallback
      logo: json['logo'] as String?,
      street: address['street'] as String? ?? '',
      city: address['city'] as String? ?? '',
      state: address['state'] as String? ?? '',
      zip: address['zip'] as String? ?? '',
      country: address['country'] as String? ?? '',
      isDisabled: json['isDisabled'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      modifiedDate: json['modifiedDate'] != null
          ? DateTime.parse(json['modifiedDate'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'organisationId': organisationId,
      'name': name,
      'phone': phone,
      'website': website,
      'timezone': timezone,
      'logo': logo,
      'address': {
        'street': street,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
      },
      'isDisabled': isDisabled,
      'createdAt': createdAt?.toIso8601String(),
      'modifiedDate': modifiedDate?.toIso8601String(),
    };
  }

  // CopyWith method for updates
  Organisation copyWith({
    String? organisationId,
    String? name,
    String? phone,
    String? website,
    String? street,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? timezone,
    String? logo,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? modifiedDate,
    bool? isDisabled,
  }) {
    return Organisation(
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      logo: logo ?? this.logo,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  /// Checks whether this organisation is equivalent to [other] for the
  /// purposes of detecting meaningful changes from the UI.
  ///
  /// Compares the fields that the settings form edits. Ignores timestamps,
  /// flags and the document id.
  bool isSameAs(Organisation other) {
    String n(String? s) => (s ?? '').trim();

    return n(name) == n(other.name) &&
        n(phone) == n(other.phone) &&
        n(website) == n(other.website) &&
        n(street) == n(other.street) &&
        n(city) == n(other.city) &&
        n(state) == n(other.state) &&
        n(zip) == n(other.zip) &&
        n(country) == n(other.country) &&
        n(timezone) == n(other.timezone);
  }

  /// Returns a list of field names that differ between this and [other].
  /// Useful for diagnostics or targeted updates.
  List<String> changedFields(Organisation other) {
    final List<String> changes = [];
    String n(String? s) => (s ?? '').trim();
    if (n(name) != n(other.name)) changes.add('name');
    if (n(phone) != n(other.phone)) changes.add('phone');
    if (n(website) != n(other.website)) changes.add('website');
    if (n(street) != n(other.street)) changes.add('street');
    if (n(city) != n(other.city)) changes.add('city');
    if (n(zip) != n(other.zip)) changes.add('zip');
    if (n(state) != n(other.state)) changes.add('state');
    if (n(country) != n(other.country)) changes.add('country');
    if (n(timezone) != n(other.timezone)) changes.add('timezone');
    return changes;
  }

  @override
  String toString() {
    return 'Organisation(organisationId: $organisationId, name: $name, phone: $phone, website: $website, street: $street, city: $city, state: $state, zip: $zip, country: $country, timezone: $timezone, logo: $logo, photoUrl: $photoUrl, isDisabled: $isDisabled, createdAt: $createdAt, modifiedDate: $modifiedDate)';
  }
}
