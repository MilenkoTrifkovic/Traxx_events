import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/utils/enums/user_role.dart';

/// Merged User model which now contains organisation and role information.
///
/// Fields:
/// - `userId` (optional) : logical user id stored in field (documents still use auto ids)
/// - `organisationId` (required) : organisation this user belongs to
/// - `role` (required) : UserRole enum
/// - `email` (required)
/// - timestamps and disabled flag
class UserModel {
  final String? userId;
  final String organisationId;
  final UserRole role;
  final String email;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDisabled;

  UserModel({
    this.userId,
    required this.organisationId,
    required this.role,
    required this.email,
    this.createdAt,
    this.modifiedAt,
    this.isDisabled = false,
  });

  /// Firestore: create (new document)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'userId': userId,
      'organisationId': organisationId,
      'role': role.name,
      'email': email,
      'isDisabled': isDisabled,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore: update (existing document)
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'userId': userId,
      'organisationId': organisationId,
      'role': role.name,
      'email': email,
      'isDisabled': isDisabled,
      // keep old createdAt, only update modifiedAt
      'modifiedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return UserModel(
      userId: data['userId'] as String?,
      // userId: id ?? data['userId'] as String?,
      organisationId: data['organisationId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? ''),
        orElse: () => UserRole.user,
      ),
      email: data['email'] as String,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      modifiedAt: (data['modifiedAt'] is Timestamp)
          ? (data['modifiedAt'] as Timestamp).toDate()
          : null,
      isDisabled: data['isDisabled'] as bool? ?? false,
    );
  }

  UserModel copyWith({
    String? userId,
    String? organisationId,
    UserRole? role,
    String? email,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDisabled,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      organisationId: organisationId ?? this.organisationId,
      role: role ?? this.role,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
