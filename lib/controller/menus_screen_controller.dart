import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
// loader not required in this controller

import 'package:cloud_firestore/cloud_firestore.dart';

class MenusScreenController extends GetxController {
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final AuthController _authController = Get.find<AuthController>();

  // Loading states
  final isLoading = false.obs;
  final isCreatingMenu = false.obs;
  final isDeletingMenu = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Form validation
  final nameError = RxnString();
  final descriptionError = RxnString();
  final formKey = GlobalKey<FormState>();

  // ❌ no category for menus

  // Image handling
  final selectedImage = Rxn<XFile>();
  final imageError = RxnString();

  // Global snackbar message controller
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void clearMessage() {
    snackbarMessageController.clearMessage();
  }

  void _showSuccessMessage(String text) {
    snackbarMessageController.showSuccessMessage(text);
  }

  void _showErrorMessage(String text) {
    snackbarMessageController.showErrorMessage(text);
  }

  /// Creates a new **Menu** (menu set) in the `menus` collection.
  ///
  /// Firestore doc structure:
  /// menus/{menuId} {
  ///   menuId,
  ///   organisationId,
  ///   name,
  ///   description,
  ///   coverImagePath,
  ///   imageUrl,
  ///   isDisabled,
  ///   createdAt,
  ///   updatedAt
  /// }
  Future<MenuModel> createMenu({
    required String name,
    String? description,
  }) async {
    try {
      if (name.trim().isEmpty) {
        throw Exception('Menu name is required');
      }

      final organisationId = _authController.organisationId;
      if (organisationId == null) {
        throw Exception('Organisation ID not found');
      }

      isCreatingMenu.value = true;

      // 1) Upload image if selected
      String? coverImagePath;
      if (selectedImage.value != null) {
        try {
          coverImagePath =
              await _storageServices.uploadImage(selectedImage.value!);
          debugPrint('Menu cover uploaded: $coverImagePath');
        } catch (e) {
          debugPrint('Failed to upload menu cover: $e');
        }
      }

      // 2) Prepare doc ref in `menus` collection
      final menusRef = FirebaseFirestore.instance.collection('menus').doc();
      final menuId = menusRef.id;

      // 3) Write initial data (with server timestamps)
      await menusRef.set({
        'menuId': menuId,
        'organisationId': organisationId,
        'name': name.trim(),
        'description':
            (description?.trim().isEmpty ?? true) ? null : description!.trim(),
        'coverImagePath': coverImagePath ?? '',
        'imageUrl': null,
        'isDisabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4) Read back to get real timestamps
      final snap = await menusRef.get();
      final data = snap.data() ?? {};

      // 5) Build MenuModel used by UI
      var createdMenu = MenuModel.fromFirestore(data, menuId);

      // 6) If we want a public URL for the cover, update the doc once more
      if (createdMenu.coverImagePath != null &&
          createdMenu.coverImagePath!.isNotEmpty) {
        try {
          final imageUrl =
              await _storageServices.loadImageURL(createdMenu.coverImagePath!);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            await menusRef.update({
              'imageUrl': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            createdMenu = MenuModel(
              id: createdMenu.id,
              organisationId: createdMenu.organisationId,
              name: createdMenu.name,
              description: createdMenu.description,
              coverImagePath: createdMenu.coverImagePath,
              imageUrl: imageUrl,
              isDisabled: createdMenu.isDisabled,
              createdAt: createdMenu.createdAt,
              updatedAt: createdMenu.updatedAt,
            );
          }
        } catch (e) {
          debugPrint('Failed to resolve menu image URL: $e');
        }
      }

      clearForm();
      _showSuccessMessage('Menu "${createdMenu.name}" created.');

      return createdMenu;
    } catch (e) {
      _showErrorMessage('Failed to create menu: $e');
      throw Exception('Failed to create menu');
    } finally {
      isCreatingMenu.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final image = await _imageServices.pickImage(ImageSource.gallery);
      if (image != null) {
        selectedImage.value = image;
        imageError.value = null;
        debugPrint('Image selected: ${image.path}');
      }
    } catch (e) {
      imageError.value = 'Failed to pick image: $e';
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  void removeImage() {
    selectedImage.value = null;
    imageError.value = null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Menu name is required';
    }
    if (value.trim().length < 2) {
      return 'Menu name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Menu name must be less than 100 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    nameError.value = null;
    descriptionError.value = null;

    final nameValidation = validateName(nameController.text);
    if (nameValidation != null) {
      nameError.value = nameValidation;
      return false;
    }

    final descriptionValidation =
        validateDescription(descriptionController.text);
    if (descriptionValidation != null) {
      descriptionError.value = descriptionValidation;
      return false;
    }

    return true;
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedImage.value = null;
    nameError.value = null;
    descriptionError.value = null;
    imageError.value = null;

    if (formKey.currentState != null) {
      formKey.currentState!.reset();
    }
  }

  /// Called by UI after popup closes with "true"
  Future<MenuModel> submitForm() async {
    if (!validateForm()) {
      throw Exception('Form validation failed');
    }

    final menu = await createMenu(
      name: nameController.text,
      description: descriptionController.text.isNotEmpty
          ? descriptionController.text
          : null,
    );
    return menu;
  }
}
