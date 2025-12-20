import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/helper/menu_category_helper.dart';

class MenuCategoryController extends GetxController {
  final SnackbarMessageController _snackbarMessageController =
      Get.find<SnackbarMessageController>();

  // Loading states
  final isLoading = false.obs;
  final isCreatingCategory = false.obs;

  // Form controllers
  final categoryNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Form validation
  final categoryNameError = RxnString();

  // Selected existing category (for display only)
  final selectedExistingCategory = RxnString();

  @override
  void onClose() {
    categoryNameController.dispose();
    super.onClose();
  }

  void clearMessage() {
    _snackbarMessageController.clearMessage();
  }

  void _showSuccessMessage(String text) {
    _snackbarMessageController.showSuccessMessage(text);
  }

  void _showErrorMessage(String text) {
    _snackbarMessageController.showErrorMessage(text);
  }

  /// Validates the category name
  String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a category name';
    }
    if (value.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Category name must be less than 50 characters';
    }

    // Check for duplicates (case-insensitive, space-insensitive)
    // Normalize: remove all spaces and convert to lowercase
    final normalizedInput = value.trim().replaceAll(' ', '').toLowerCase();
    final existingCategories = MenuCategoryHelper.getAllCategories();
    
    for (final existing in existingCategories) {
      final normalizedExisting = existing.replaceAll(' ', '').toLowerCase();
      if (normalizedExisting == normalizedInput) {
        return 'This category already exists';
      }
    }

    return null;
  }

  /// Validates the form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    categoryNameError.value = null;

    final validation = validateCategoryName(categoryNameController.text);
    if (validation != null) {
      categoryNameError.value = validation;
      return false;
    }

    return true;
  }

  /// Clears the form
  void clearForm() {
    categoryNameController.clear();
    categoryNameError.value = null;
    selectedExistingCategory.value = null;

    if (formKey.currentState != null) {
      formKey.currentState!.reset();
    }
  }

  /// Adds a new custom category to the organisation
  /// Uses OrganisationController.updateOrganisation() for persistence
  Future<String> addCategory(String categoryName) async {
    try {
      isCreatingCategory.value = true;

      // Get organisation controller and current organisation
      final orgController = Get.find<OrganisationController>();
      final org = orgController.organisation.value;
      
      if (org == null) {
        throw Exception('Organisation not loaded');
      }

      // Format the category name consistently
      final formattedCategoryName = MenuCategoryHelper.formatCategoryName(
        categoryName.trim(),
      );

      // Get current categories or empty list
      final currentCategories = org.customMenuCategories ?? [];
      
      // Check for duplicates (case-insensitive, space-insensitive)
      final normalizedNew = formattedCategoryName.replaceAll(' ', '').toLowerCase();
      for (final existing in currentCategories) {
        final normalizedExisting = existing.replaceAll(' ', '').toLowerCase();
        if (normalizedExisting == normalizedNew) {
          throw Exception('Category already exists');
        }
      }

      // Add new category
      final updatedCategories = [...currentCategories, formattedCategoryName];
      
      // Update organisation with new categories using existing method
      final updatedOrg = org.copyWith(
        customMenuCategories: updatedCategories,
      );
      
      final success = await orgController.updateOrganisation(updatedOrg);
      
      if (!success) {
        throw Exception('Failed to update organisation');
      }

      _showSuccessMessage(
        'Category "$formattedCategoryName" added successfully.',
      );

      return formattedCategoryName;
    } catch (e) {
      _showErrorMessage('Failed to add category: $e');
      rethrow;
    } finally {
      isCreatingCategory.value = false;
    }
  }

  /// Called by UI after form validation
  Future<String> submitForm() async {
    if (!validateForm()) {
      throw Exception('Form validation failed');
    }

    final categoryName = await addCategory(categoryNameController.text);
    return categoryName;
  }

  /// Gets all existing categories for display
  List<String> getExistingCategories() {
    return MenuCategoryHelper.getAllCategories();
  }

  /// Checks if a category is custom (not from enum)
  bool isCustomCategory(String categoryName) {
    final orgController = Get.find<OrganisationController>();
    final customCategories = orgController.organisation.value?.customMenuCategories ?? [];
    
    // Case-insensitive, space-insensitive comparison
    final normalizedCategoryName = categoryName.replaceAll(' ', '').toLowerCase();
    return customCategories.any(
      (custom) => custom.replaceAll(' ', '').toLowerCase() == normalizedCategoryName,
    );
  }

  /// Deletes a custom category from the organisation
  Future<bool> deleteCategory(String categoryName) async {
    try {
      isLoading.value = true;

      // Get organisation controller and current organisation
      final orgController = Get.find<OrganisationController>();
      final org = orgController.organisation.value;
      
      if (org == null) {
        throw Exception('Organisation not loaded');
      }

      // Get current categories
      final currentCategories = org.customMenuCategories ?? [];
      
      // Find and remove the category (case-insensitive, space-insensitive)
      final normalizedCategoryName = categoryName.replaceAll(' ', '').toLowerCase();
      final updatedCategories = currentCategories
          .where((cat) => cat.replaceAll(' ', '').toLowerCase() != normalizedCategoryName)
          .toList();

      // Check if anything was actually removed
      if (updatedCategories.length == currentCategories.length) {
        throw Exception('Category not found');
      }

      // Update organisation with new categories
      final updatedOrg = org.copyWith(
        customMenuCategories: updatedCategories,
      );
      
      final success = await orgController.updateOrganisation(updatedOrg);
      
      if (!success) {
        throw Exception('Failed to update organisation');
      }

      _showSuccessMessage(
        'Category "$categoryName" deleted successfully.',
      );

      return true;
    } catch (e) {
      _showErrorMessage('Failed to delete category: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
