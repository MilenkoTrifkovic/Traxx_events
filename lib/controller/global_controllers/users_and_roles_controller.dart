import 'package:get/get.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/services/firestore_services/user_and_role_firestore_services.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';

class UsersAndRolesController extends GetxController {
  RxList<UserModel> usersWithRoles = <UserModel>[].obs;
  final RxBool isLoading = false.obs; // ✅ Add loading state
  final UserAndRoleFirestoreServices _svc = UserAndRoleFirestoreServices();
  // Resolve snackbar controller once — it should be registered at app startup.
  final SnackbarMessageController snackbarController =
      Get.find<SnackbarMessageController>();

  /// Loads all active users with their roles for the current organisation
  /// (organisation id is obtained from the global `OrganisationController`)
  /// and updates the observable `usersWithRoles` list.
  Future<void> loadUsersWithRoles() async {
    try {
      isLoading.value = true; // ✅ Set loading state
      print('🔵 Loading users with roles...');
      
      final orgCtrl = Get.find<OrganisationController>();
      final organisationId = orgCtrl.organisationId;
      if (organisationId.isEmpty) {
        throw Exception('organisationId is empty in OrganisationController');
      }

      print('🔵 Fetching users for organisation: $organisationId');
      final list =
          await _svc.getAllUsersWithRole(organisationId: organisationId);
      usersWithRoles.assignAll(list);
      print('✅ Users with roles loaded: ${usersWithRoles.length}');
    } on Exception catch (e) {
      // Keep simple logging here; callers can catch/rethrow if needed.
      print('❌ Error loading users with roles: $e');
      rethrow;
    } finally {
      isLoading.value = false; // ✅ Clear loading state
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

  /// Soft deletes a user by setting isDisabled to true.
  /// Removes the user from the local observable list.
  Future<void> deleteUser(String userId) async {
    try {
      print('🔵 Deleting user: $userId');
      await _svc.deleteUser(userId: userId);
      
      // Remove from local list
      usersWithRoles.removeWhere((u) => u.userId == userId);
      print('✅ User removed from local list');
      
      snackbarController.showSuccessMessage('User disabled successfully');
    } on Exception catch (e) {
      print('❌ Error deleting user: $e');
      snackbarController.showErrorMessage('Error disabling user');
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
