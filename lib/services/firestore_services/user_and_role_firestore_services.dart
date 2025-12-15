import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/utils/collect_ref.dart';
import 'package:uuid/uuid.dart';

// /// Aggregates a user document with its role document.
// class UserAndRole {
//   final UserModel user;
//   final OrganisationUserRole role;

//   UserAndRole({required this.user, required this.role});
// }

/// Firestore services that keeps `users` and `roles` documents in sync.
///
/// Both documents are written in a single batch so they are either created
/// together or not at all.
class UserAndRoleFirestoreServices {
  UserAndRoleFirestoreServices({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
    _db.collection(usersCol);

  /// Creates a user document. Documents use Firestore auto-IDs, while a
  /// logical `userId` field is stored inside the document. The caller may
  /// provide `user.userId`; otherwise a UUID is generated.
  // Future<void> createUserWithRole({
  //   required UserModel user,
  // }) async {
  //   final userFieldId =
  //       (user.userId != null && user.userId!.isNotEmpty) ? user.userId! : const Uuid().v4();

  //   final userDocRef = _usersRef.doc();
  //   await userDocRef.set(user.copyWith(userId: userFieldId).toFirestoreCreate());
  // }

  /// Saves a user model to Firestore and returns the saved model.
  /// The document uses an auto-generated Firestore id while the logical
  /// `userId` field is stored inside the document. The returned model has
  /// the `userId` field set (either provided or newly generated).
  Future<UserModel> saveUser({required UserModel user}) async {
    final userFieldId =
        (user.userId != null && user.userId!.isNotEmpty) ? user.userId! : const Uuid().v4();

    final toSave = user.copyWith(userId: userFieldId);
    final userDocRef = _usersRef.doc();
    await userDocRef.set(toSave.toFirestoreCreate());

    // Return the model that was saved (timestamps will be set server-side).
    return toSave;
  }
  Future<void> deleteUser({required String userId}) async {
    try {
      final snap = await _usersRef
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        print('No user found with userId: $userId');
        return;
      }

      final docRef = snap.docs.first.reference;
      await docRef.delete();
      print('User with userId: $userId deleted successfully.');
    } on FirebaseException catch (e) {
      print('Firestore error deleting user: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error deleting user: $e');
      rethrow;
    }
  }
  Future<UserModel> updateUser({required UserModel user}) async {
    if (user.userId == null || user.userId!.isEmpty) {
      throw ArgumentError('user.userId is required to update user');
    }

    try {
      final snap = await _usersRef
          .where('userId', isEqualTo: user.userId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw Exception('User not found for userId: ${user.userId}');
      }

      final docRef = snap.docs.first.reference;
      await docRef.set(user.toFirestoreUpdate(), SetOptions(merge: true));

      return user;
    } on FirebaseException catch (e) {
      print('Firestore error updating user: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating user: $e');
      rethrow;
    }
  }

  /// Fetches a single user document by logical userId (stored in field)
  /// and organisationId. Returns `null` if not found.
  Future<UserModel?> getUserWithRole({
    required String userId,
    required String organisationId,
  }) async {
    try {
      final snap = await _usersRef
          .where('userId', isEqualTo: userId)
          .where('organisationId', isEqualTo: organisationId)
          .where('isDisabled', isEqualTo: false)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return UserModel.fromFirestore(d.data(), d.id);
    } on FirebaseException catch (e) {
      print('Firestore error fetching user: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching user: $e');
      rethrow;
    }
  }

  /// Fetches all active users for a given organisation.
  ///
  /// Returns a list of `UserModel`. Query is performed directly on the
  /// `users` collection using `organisationId` and `isDisabled` filters.
  Future<List<UserModel>> getAllUsersWithRole({
    required String organisationId,
  }) async {
    try {
      final userSnap = await _usersRef
          .where('organisationId', isEqualTo: organisationId)
          .where('isDisabled', isEqualTo: false)
          .get();

      if (userSnap.docs.isEmpty) return <UserModel>[];

      final users = userSnap.docs
          .map((d) => UserModel.fromFirestore(d.data(), d.id))
          .toList();

      return users;
    } on FirebaseException catch (e) {
      print('Firestore error fetching users: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching users: $e');
      rethrow;
    }
  }

  // /// Updates existing user and role docs together.
  // /// Throws if the role document cannot be found.
  // Future<void> updateUserWithRole({
  //   required UserModel user,
  //   required OrganisationUserRole role,
  // }) async {
  //   final userId = user.userId;
  //   if (userId == null || userId.isEmpty) {
  //     throw ArgumentError('user.userId is required to update user & role');
  //   }
  //   if (role.userId != userId) {
  //     throw ArgumentError('role.userId must match user.userId');
  //   }

  //   final userDocRef = _usersRef.doc(userId);
  //   final roleDocRef = await _resolveRoleDocRef(role);

  //   final batch = _db.batch();
  //   batch.set(userDocRef, user.toFirestoreUpdate(), SetOptions(merge: true));
  //   batch.set(roleDocRef, role.copyWith(id: roleDocRef.id).toFirestoreUpdate(),
  //       SetOptions(merge: true));

  //   await batch.commit();
  // }

  // /// Soft deletes user and role by marking `isDisabled` true.
  // Future<void> disableUserWithRole({
  //   required String userId,
  //   required String organisationId,
  // }) async {
  //   final roleDocRef = await _findRoleDocRef(
  //     userId: userId,
  //     organisationId: organisationId,
  //   );

  //   final batch = _db.batch();
  //   batch.set(
  //     _usersRef.doc(userId),
  //     {
  //       'isDisabled': true,
  //       'modifiedAt': FieldValue.serverTimestamp(),
  //     },
  //     SetOptions(merge: true),
  //   );
  //   batch.set(
  //     roleDocRef,
  //     {
  //       'isDisabled': true,
  //       'modifiedAt': FieldValue.serverTimestamp(),
  //     },
  //     SetOptions(merge: true),
  //   );

  //   await batch.commit();
  // }

  // Future<DocumentReference<Map<String, dynamic>>> _resolveRoleDocRef(
  //     OrganisationUserRole role) async {
  //   // If a logical role.id (field) is provided, try to find the document
  //   // that contains that `id` field. This keeps the document name as an
  //   // auto-generated Firestore id while allowing callers to use their own
  //   // `id` value stored inside the document.
  //   if (role.id != null && role.id!.isNotEmpty) {
  //     final byField = await _rolesRef
  //         .where('id', isEqualTo: role.id)
  //         .limit(1)
  //         .get();
  //     if (byField.docs.isNotEmpty) {
  //       return byField.docs.first.reference;
  //     }

  //     // Backwards compatibility: if someone passed an old-style doc id in
  //     // role.id, attempt to resolve it as a document id as a fallback.
  //     final possibleDocRef = _rolesRef.doc(role.id);
  //     final possibleDoc = await possibleDocRef.get();
  //     if (possibleDoc.exists) {
  //       return possibleDocRef;
  //     }

  //     throw Exception('Role document not found for id: ${role.id}');
  //   }

  //   return _findRoleDocRef(
  //     userId: role.userId,
  //     organisationId: role.organisationId,
  //   );
  // }

  // Future<DocumentReference<Map<String, dynamic>>> _findRoleDocRef({
  //   required String userId,
  //   required String organisationId,
  // }) async {
  //   final existing = await _rolesRef
  //       .where('userId', isEqualTo: userId)
  //       .where('organisationId', isEqualTo: organisationId)
  //       .limit(1)
  //       .get();

  //   if (existing.docs.isEmpty) {
  //     throw Exception(
  //         'Role document not found for userId: $userId, organisationId: $organisationId');
  //   }

  //   return existing.docs.first.reference;
  // }
}
