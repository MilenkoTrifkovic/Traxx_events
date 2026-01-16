import 'package:cloud_firestore/cloud_firestore.dart';

class SalesPersonModel {
  /// Firestore document id
  final String docId;

  /// Business id field (optional, can be set to doc id)
  final String? salesPersonId;

  /// Reference code for the sales person (auto-generated)
  final String? refCode;

  final String name;
  final String email;

  /// Address fields
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  final DateTime? createdAt;
  final DateTime? modifiedAt;

  final bool isDisabled;
  final bool isActive;

  SalesPersonModel({
    this.docId = '',
    this.salesPersonId,
    this.refCode,
    required this.name,
    required this.email,
    this.address,
    this.city,
    this.state,
    this.country,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
    this.isActive = true,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      if (docId.isNotEmpty) 'docId': docId,
      if (salesPersonId != null && salesPersonId!.trim().isNotEmpty)
        'salesPersonId': salesPersonId,
      if (refCode != null && refCode!.trim().isNotEmpty)
        'refCode': refCode,
      'name': name,
      'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      'isDisabled': isDisabled,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      if (docId.isNotEmpty) 'docId': docId,
      if (salesPersonId != null && salesPersonId!.trim().isNotEmpty)
        'salesPersonId': salesPersonId,
      if (refCode != null && refCode!.trim().isNotEmpty)
        'refCode': refCode,
      'name': name,
      'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      'isDisabled': isDisabled,
      'isActive': isActive,
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SalesPersonModel.fromFirestore(
      Map<String, dynamic> data, [String? id]) {
    DateTime? parseTimestamp(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate();
      if (t is DateTime) return t;
      return null;
    }

    // Resolve docId: prefer Firestore doc id param, then stored docId, then fallback to salesPersonId
    final resolvedDocId = (id?.trim().isNotEmpty == true)
        ? id!.trim()
        : (data['docId']?.toString().trim().isNotEmpty == true)
            ? data['docId'].toString().trim()
            : (data['salesPersonId']?.toString().trim().isNotEmpty == true)
                ? data['salesPersonId'].toString().trim()
                : '';

    final salesPersonIdField =
        (data['salesPersonId']?.toString().trim().isNotEmpty == true)
            ? data['salesPersonId'].toString().trim()
            : null;

    final refCodeField =
        (data['refCode']?.toString().trim().isNotEmpty == true)
            ? data['refCode'].toString().trim()
            : null;

    return SalesPersonModel(
      docId: resolvedDocId,
      salesPersonId: salesPersonIdField,
      refCode: refCodeField,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      isDisabled: data['isDisabled'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: parseTimestamp(data['createdAt']),
      modifiedAt: parseTimestamp(data['modifiedAt']),
    );
  }

  SalesPersonModel copyWith({
    String? docId,
    String? salesPersonId,
    String? refCode,
    String? name,
    String? email,
    String? address,
    String? city,
    String? state,
    String? country,
    bool? isDisabled,
    bool? isActive,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return SalesPersonModel(
      docId: docId ?? this.docId,
      salesPersonId: salesPersonId ?? this.salesPersonId,
      refCode: refCode ?? this.refCode,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      isDisabled: isDisabled ?? this.isDisabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  String toString() {
    return 'SalesPersonModel('
        'docId: $docId, '
        'salesPersonId: $salesPersonId, '
        'refCode: $refCode, '
        'name: $name, '
        'email: $email, '
        'address: $address, '
        'city: $city, '
        'state: $state, '
        'country: $country, '
        'isDisabled: $isDisabled, '
        'isActive: $isActive, '
        'createdAt: $createdAt, '
        'modifiedAt: $modifiedAt'
        ')';
  }
}
