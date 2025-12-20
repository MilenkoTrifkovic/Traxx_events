import 'package:cloud_firestore/cloud_firestore.dart';

/// A model representing a venue that can host events.
///
/// This class handles venue data including basic information,
/// optional description and photo, and tracking metadata.
class Venue {
  /// Unique identifier for the venue
  final String? venueID;

  /// The organization that owns this venue
  final String organisationId;

  /// The name of the venue
  final String name;

  /// Optional description of the venue
  final String? description;

  /// Optional URL to the venue's photo (primary/first photo)
  final String? photoPath;

  /// Optional list of multiple photo paths
  final List<String>? photoPaths;

  // Address fields - Required as a complete map
  final String street; // address.street
  final String city; // address.city
  final String zip; // address.zip
  final String state; // address.state
  final String country; // address.country

  /// Optional in-memory download URL for the venue's photo.
  ///
  /// This field is NOT written to Firestore and is used only at runtime
  /// (for example, when a download URL has been resolved from a storage path).
  final String? photoUrl;

  /// Optional in-memory map linking photo paths to their download URLs.
  ///
  /// This field is NOT written to Firestore and is used only at runtime.
  /// Maps storage paths (from photoPaths) to their corresponding download URLs.
  /// This ensures path-URL integrity and makes operations like deletion safer.
  final Map<String, String>? photoPathToUrlMap;

  /// Getter that returns list of photo URLs from the map.
  ///
  /// This maintains backward compatibility while using the safer map structure.
  List<String> get photoUrls => photoPathToUrlMap?.values.toList() ?? [];

  /// Timestamp when the venue was created (optional - uses server timestamp when null)
  final DateTime? createdAt;

  /// Timestamp when the venue was last modified (optional - uses server timestamp when null)
  final DateTime? modifiedAt;

  /// Whether the venue is disabled/inactive
  final bool isDisabled;

  /// Creates a new Venue instance
  String get fullAddress {
    return '$street, $city, $state, $zip, $country';
  }

  Venue({
    this.venueID,
    required this.organisationId,
    required this.name,
    this.description,
    this.photoPath,
    this.photoPaths,
    this.photoUrl,
    this.photoPathToUrlMap,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    required this.street,
    required this.city,
    required this.zip,
    required this.state,
    required this.country,
  });

  /// Creates a Venue from a Firestore document snapshot
  factory Venue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Venue(
      // venueID: doc.id,
      venueID: data['venueID'],
      organisationId: data['organisationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      photoPath: data['photoPath'],
      photoPaths: data['photoPaths'] != null
          ? List<String>.from(data['photoPaths'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedAt:
          (data['modifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDisabled: data['isDisabled'] ?? false,
      street: data['address']?['street'] ?? '',
      city: data['address']?['city'] ?? '',
      zip: data['address']?['zip'] ?? '',
      state: data['address']?['state'] ?? '',
      country: data['address']?['country'] ?? '',
    );
  }

  /// Creates a Venue from a JSON map
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      venueID: json['venueID'],
      organisationId: json['organisationId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      photoPath: json['photoPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'])
          : DateTime.now(),
      isDisabled: json['isDisabled'] ?? false,
      street: json['address']?['street'] ?? '',
      city: json['address']?['city'] ?? '',
      zip: json['address']?['zip'] ?? '',
      state: json['address']?['state'] ?? '',
      country: json['address']?['country'] ?? '',
    );
  }

  /// Converts the Venue to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'venueID': venueID,
      'organisationId': organisationId,
      'name': name,
      'description': description,
      'photoPath': photoPath,
      if (photoPaths != null) 'photoPaths': photoPaths,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
      'isDisabled': isDisabled,
      'address': {
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
        'country': country,
      },
    };
  }

  /// Converts the Venue to a Firestore-compatible map for creating new venues
  /// Uses server timestamp for both createdAt and modifiedAt
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'venueID': venueID,
      'organisationId': organisationId,
      'name': name,
      'description': description,
      'photoPath': photoPath,
      if (photoPaths != null) 'photoPaths': photoPaths,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
      'isDisabled': isDisabled,
      'address': {
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
        'country': country,
      },
    };
  }

  /// Converts the Venue to a Firestore-compatible map for updates
  /// Only uses server timestamp for modifiedAt
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'organisationId': organisationId,
      'name': name,
      'description': description,
      if (photoPath != null) 'photoPath': photoPath,
      if (photoPaths != null) 'photoPaths': photoPaths,
      'modifiedAt': FieldValue.serverTimestamp(),
      'isDisabled': isDisabled,
      'address': {
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
        'country': country,
      },
    };
  }

  /// Converts the Venue to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'venueID': venueID,
      'organisationId': organisationId,
      'name': name,
      'description': description,
      'photoPath': photoPath,
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'isDisabled': isDisabled,
      'address': {
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
        'country': country,
      },
    };
  }

  /// Creates a copy of this Venue with updated values
  Venue copyWith({
    String? venueID,
    String? organisationId,
    String? name,
    String? description,
    String? photoPath,
    List<String>? photoPaths,
    String? photoUrl,
    Map<String, String>? photoPathToUrlMap,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
    String? street,
    String? city,
    String? zip,
    String? state,
    String? country,
  }) {
    return Venue(
      venueID: venueID ?? this.venueID,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      photoPaths: photoPaths ?? this.photoPaths,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPathToUrlMap: photoPathToUrlMap ?? this.photoPathToUrlMap,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
      street: street ?? this.street,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  /// Updates the modifiedAt timestamp to now
  Venue updateModifiedAt() {
    return copyWith(modifiedAt: DateTime.now());
  }

  /// Returns a string representation of the venue
  @override
  String toString() {
    return 'Venue{venueID: $venueID, organisationId: $organisationId, name: $name, description: $description, '
        'photoPath: $photoPath, photoUrl: $photoUrl, createdAt: $createdAt, modifiedAt: $modifiedAt, '
        'isDisabled: $isDisabled, street: $street, city: $city, zip: $zip, state: $state, country: $country}';
  }

  /// Checks if two venues are equal
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Venue &&
        other.venueID == venueID &&
        other.organisationId == organisationId &&
        other.name == name &&
        other.description == description &&
        other.photoPath == photoPath &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.isDisabled == isDisabled &&
        other.street == street &&
        other.city == city &&
        other.zip == zip &&
        other.state == state &&
        other.country == country;
  }

  /// Returns the hash code for this venue
  @override
  int get hashCode {
    return venueID.hashCode ^
        organisationId.hashCode ^
        name.hashCode ^
        description.hashCode ^
        (photoPath?.hashCode ?? 0) ^
        (photoUrl?.hashCode ?? 0) ^
        (createdAt?.hashCode ?? 0) ^
        (modifiedAt?.hashCode ?? 0) ^
        isDisabled.hashCode ^
        street.hashCode ^
        city.hashCode ^
        zip.hashCode ^
        state.hashCode ^
        country.hashCode;
  }
}
