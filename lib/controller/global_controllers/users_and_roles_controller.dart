import 'package:get/get.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/services/firestore_services/user_and_role_firestore_services.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';

class UsersAndRolesController extends GetxController {
  RxList<UserModel> usersWithRoles = <UserModel>[].obs;
  final UserAndRoleFirestoreServices _svc = UserAndRoleFirestoreServices();
  // Resolve snackbar controller once — it should be registered at app startup.
  final SnackbarMessageController snackbarController =
      Get.find<SnackbarMessageController>();

  /// Loads all active users with their roles for the current organisation
  /// (organisation id is obtained from the global `OrganisationController`)
  /// and updates the observable `usersWithRoles` list.
  Future<void> loadUsersWithRoles() async {
    try {
      final orgCtrl = Get.find<OrganisationController>();
      final organisationId = orgCtrl.organisationId;
      if (organisationId.isEmpty) {
        throw Exception('organisationId is empty in OrganisationController');
      }

      final list =
          await _svc.getAllUsersWithRole(organisationId: organisationId);
      usersWithRoles.assignAll(list);
    } on Exception catch (e) {
      // Keep simple logging here; callers can catch/rethrow if needed.
      print('Error loading users with roles: $e');
      rethrow;
    } finally {
      print('Users with roles updated: ${usersWithRoles.length}');
    }
  }

  /// Adds a new user to Firestore and updates the observable list on success.
  Future<UserModel> addUser(UserModel user) async {
    try {
      final saved = await _svc.saveUser(user: user);
      // Optimistically update local list with the saved model.
      usersWithRoles.add(saved);
      snackbarController.showSuccessMessage('User ${saved.email} created');
      return saved;
    } on Exception catch (e) {
      print('Error adding user: $e');
      snackbarController.showErrorMessage('Error creating user');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _svc.deleteUser(userId: userId);
      usersWithRoles.removeWhere((u) => u.userId == userId);
      snackbarController.showSuccessMessage('User deleted successfully');
    } on Exception catch (e) {
      print('Error deleting user: $e');
      snackbarController.showErrorMessage('Error deleting user');
      rethrow;
    }
  }
  Future<void> updateUser(UserModel user) async {
    try {
      final updated = await _svc.updateUser(user: user);
      final index =
          usersWithRoles.indexWhere((u) => u.userId == updated.userId);
      if (index != -1) {
        usersWithRoles[index] = updated;
        usersWithRoles.refresh();
      }
      snackbarController.showSuccessMessage('User ${updated.email} updated');
    } on Exception catch (e) {
      print('Error updating user: $e');
      snackbarController.showErrorMessage('Error updating user');
      rethrow;
    }
  }
}
