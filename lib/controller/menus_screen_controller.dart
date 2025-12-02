import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
// loader not required in this controller

/// Controller for managing venue operations including creation, deletion, and form validation.
class MenusScreenController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final AuthController _authController = Get.find<AuthController>();

  // Loading states
  final isLoading = false.obs;
  final isCreatingMenuItem = false.obs;
  final isDeletingMenuItem = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Form validation
  final nameError = RxnString();
  final descriptionError = RxnString();
  final formKey = GlobalKey<FormState>();

  // Category selection for menu item
  final selectedCategory = Rx<MenuCategory?>(MenuCategory.other);

  // Image handling
  final selectedImage = Rxn<XFile>();
  final imageError = RxnString();

  // Use global snackbar message controller
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  // Venues list - commented out for separate controller
  // final venues = <Venue>[].obs;

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Clears the current global snackbar message
  void clearMessage() {
    snackbarMessageController.clearMessage();
  }

  /// Shows a success message globally
  void _showSuccessMessage(String text) {
    snackbarMessageController.showSuccessMessage(text);
  }

  /// Shows an error message globally
  void _showErrorMessage(String text) {
    snackbarMessageController.showErrorMessage(text);
  }

  /// Fetches all venues for the current organisation
  // Future<void> fetchVenues() async {
  //   try {
  //     isLoading.value = true;
  //     final organisationId = _authController.organisationId;
  //     if (organisationId == null) {
  //       throw Exception('Organisation ID not found');
  //     }

  //     final venuesList = await _firestoreServices.getVenues(organisationId);
  //     venues.assignAll(venuesList);
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Failed to fetch venues: $e',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red.withOpacity(0.8),
  //       colorText: Colors.white,
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  /// Creates a new menu item with required parameters
  ///
  /// Required:
  /// - name
  /// - category
  /// Optional:
  /// - description
  /// - image
  Future<MenuItem> createMenuItem({
    required String name,
    required MenuCategory category,
    String? description,
  }) async {
    try {
      // Validate required fields
      if (name.trim().isEmpty) {
        throw Exception('Menu item name is required');
      }

      final organisationId = _authController.organisationId;
      if (organisationId == null) {
        throw Exception('Organisation ID not found');
      }

      isCreatingMenuItem.value = true;

      // Upload image if selected
      String? photoPath;
      if (selectedImage.value != null) {
        try {
          photoPath = await _storageServices.uploadImage(selectedImage.value!);
          print('Image uploaded successfully: $photoPath');
        } catch (e) {
          print('Failed to upload image: $e');
          // Continue without image - image upload is optional
        }
      }

      // Create menu item object
      final menuItem = MenuItem(
        organisationId: organisationId,
        name: name.trim(),
        category: category,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        imagePath: photoPath,
        isDisabled: false,
      );

      // Save to Firestore
      print('Creating menu item: ${menuItem.imagePath}');
      final created = await _firestoreServices.createMenuItem(menuItem);
      print('Creating menu item: ${created.imagePath}');

      // Attempt to load a public URL for the uploaded image (if any)
      final imageUrl = created.imagePath == null
          ? null
          : await _storageServices.loadImageURL(created.imagePath);
      print('Loaded image URL: $imageUrl');

      // copyWith returns a new MenuItem instance; it does NOT mutate `created`.
      // Assign the returned copy to a variable and persist the change if needed.
      var result = created;
      if (imageUrl != null) {
        result = created.copyWith(imageUrl: imageUrl);
        // Persist the imageUrl back to Firestore so future reads include it
        try {
          await _firestoreServices.updateMenuItem(result);
        } catch (e) {
          print('Failed to update menu item with imageUrl: $e');
        }
      }

      print('Menu item created with imageUrl: ${result.imageUrl}');

      // Clear form
      clearForm();

  _showSuccessMessage('Menu item "${result.name}" created successfully!');
  return result;
    } catch (e) {
      _showErrorMessage('Failed to create menu item: $e');
      throw Exception('Failed to create menu item');
    } finally {
      isCreatingMenuItem.value = false;
    }
  }

  /// Picks an image from the device gallery
  Future<void> pickImage() async {
    try {
      final image = await _imageServices.pickImage(ImageSource.gallery);
      if (image != null) {
        selectedImage.value = image;
        imageError.value = null;
        print('Image selected: ${image.path}');
      }
    } catch (e) {
      imageError.value = 'Failed to pick image: $e';
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  /// Removes the selected image
  void removeImage() {
    selectedImage.value = null;
    imageError.value = null;
  }

  /// Validates the menu item name
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Menu item name is required';
    }
    if (value.trim().length < 2) {
      return 'Menu item name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Menu item name must be less than 100 characters';
    }
    return null;
  }

  /// Validates the venue description (optional)
  String? validateDescription(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  /// Validates the entire form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    // Clear any previous errors
    nameError.value = null;
    descriptionError.value = null;

    // Additional validation if needed
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

  /// Clears the form and resets all fields
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedImage.value = null;
    nameError.value = null;
    descriptionError.value = null;
    imageError.value = null;

    // Reset form validation state
    if (formKey.currentState != null) {
      formKey.currentState!.reset();
    }
  }

  /// Submits the form and creates the menu item
  Future<MenuItem> submitForm() async {
    if (validateForm()) {
      final category = selectedCategory.value ?? MenuCategory.other;
      final item = await createMenuItem(
        name: nameController.text,
        category: category,
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text
            : null,
      );
      return item;
    }
    throw Exception('Form validation failed');
  }
}
