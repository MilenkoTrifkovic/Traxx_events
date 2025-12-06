import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

/// Represents a user's role within an organisation.
///
/// Fields:
/// - `id` (optional): document id
/// - `organisationId` (required)
/// - `userId` (required)
/// - `role` (required) : [UserRole] enum
/// - `createdAt`, `modifiedAt`, `isDisabled` (optional)
class OrganisationUserRole {
  final String? id;
  final String organisationId;
  final String userId;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;

  OrganisationUserRole({
    this.id,
    required this.organisationId,
    required this.userId,
    required this.role,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'id': id,
      'organisationId': organisationId,
      'userId': userId,
      'role': role.name,
      'isDisabled': isDisabled,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'id': id,
      'organisationId': organisationId,
      'userId': userId,
      'role': role.name,
      'isDisabled': isDisabled,
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory OrganisationUserRole.fromFirestore(Map<String, dynamic> data,
      [String? id]) {
    return OrganisationUserRole(
      id: id ?? data['id'] as String?,
      organisationId: data['organisationId'] as String,
      userId: data['userId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? ''),
        orElse: () => UserRole.user,
      ),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      modifiedAt: (data['modifiedAt'] is Timestamp)
          ? (data['modifiedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }

  OrganisationUserRole copyWith({
    String? id,
    String? organisationId,
    String? userId,
    UserRole? role,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
  }) {
    return OrganisationUserRole(
      id: id ?? this.id,
      organisationId: organisationId ?? this.organisationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
