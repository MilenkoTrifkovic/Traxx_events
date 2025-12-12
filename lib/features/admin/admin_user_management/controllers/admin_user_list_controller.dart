import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/users_and_roles_controller.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

class AdminUserListController extends GetxController {
  final usersController = Get.find<UsersAndRolesController>();
  final OrganisationController organisationController =
      Get.find<OrganisationController>();

  final formKey = GlobalKey<FormState>();
  // Form controllers
  final email = TextEditingController();
  final role = Rx<UserRole?>(UserRole.planner);

  late final String organisationId;

  AdminUserListController() {
    organisationId = organisationController.organisationId;
  }

  /// Validates an email address for the Add User form.
  /// Returns a string error message when invalid, or null when valid.
  String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';

    // Basic email regex. Keep it simple to avoid rejecting valid addresses.
    final emailRegex = RegExp(r"^[\w\-\.]+@([\w\-]+\.)+[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';

    return null;
  }

  /// Validates the entire Add User form.
  /// Returns true when the form is valid, false otherwise.
  bool validateForm() {
    // Validate form fields (email via validator on the field)
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    // Role must be selected
    if (role.value == null) {
      // Use the shared snackbar controller from usersController to show an error
      try {
        usersController.snackbarController.showErrorMessage('Role is required');
      } catch (_) {
        // If snackbar controller isn't available for some reason, silently continue
      }
      return false;
    }

    return true;
  }

  Future<void> submitForm() async {
    final emailValue = email.text.trim();
    final roleValue = role.value;

    if (roleValue == null) {
      throw Exception('Role is null in submitForm');
    }

    final newUser = UserModel(
      organisationId: organisationId,
      role: roleValue,
      email: emailValue,
    );

    await usersController.addUser(newUser);
  }

  Future<void> updateUser({required String userId}) async {
    final updatedUser = UserModel(
      organisationId: organisationId,
      userId: userId,
      role: role.value!,
      email: email.text.trim(),
    );

    await usersController.updateUser(updatedUser);
  }

  void updateRoleAndEmail(UserModel user) {
    role.value = user.role;
    email.text = user.email;
  }

  @override
  void onInit() {
    super.onInit();
    usersController.loadUsersWithRoles(); // load immediately
    // organisationId = organisationController.organisationId;
  }

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}
