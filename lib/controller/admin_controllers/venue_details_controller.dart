import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class VenueDetailsController {
  final FirestoreServices _firestoreServices;
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices;
  final AuthController _authController;
  final VenuesController _venuesController;

  final isLoading = false.obs;
  final isCreatingVenue = false.obs;
  final isDeletingVenue = false.obs;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  final nameError = RxnString();
  final descriptionError = RxnString();
  final formKey = GlobalKey<FormState>();

  final selectedImage = Rxn<XFile>();
  final imageError = RxnString();

  // Use global snackbar message controller
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();
  Venue? venue;

  // Menu item form controllers and state
  final menuFormKey = GlobalKey<FormState>();
  final menuNameController = TextEditingController();
  final menuDescriptionController = TextEditingController();
  final selectedCategory = Rxn<MenuCategory>();
  final isCreatingMenuItem = false.obs;

  VenueDetailsController()
      : _storageServices = Get.find<StorageServices>(),
        _authController = Get.find<AuthController>(),
        _firestoreServices = Get.find<FirestoreServices>(),
        _venuesController = Get.find<VenuesController>();

  Future<void> loadVenue(String venueId) async {
    final fetchedVenue = _venuesController.getVenueById(venueId);
    venue = fetchedVenue;
    if (venue == null) {
      try {
        venue = await _firestoreServices.getVenueById(venueId);
      } catch (e) {
        print('Error fetching venue: $e');
      }
    }
  }

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

  // Validation methods
  String? validateMenuName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 120) {
      return 'Name must be less than 120 characters';
    }
    return null;
  }

  String? validateMenuDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  // Clear form
  void clearMenuForm() {
    menuNameController.clear();
    menuDescriptionController.clear();
    selectedCategory.value = null;
    selectedImage.value = null;
    imageError.value = null;
    if (menuFormKey.currentState != null) {
      menuFormKey.currentState!.reset();
    }
  }

  // Image picker for menu item
  // Future<void> pickImage() async {
  //   try {
  //     final image = await _imageServices.pickImage(ImageSource.gallery);
  //     if (image != null) {
  //       selectedImage.value = image;
  //       imageError.value = null;
  //     }
  //   } catch (e) {
  //     imageError.value = 'Failed to pick image: $e';
  //     snackbarMessageController.showErrorMessage('Failed to pick image: $e');
  //   }
  // }

  void removeImage() {
    selectedImage.value = null;
    imageError.value = null;
  }

  // Submit menu item
  Future<void> submitMenuItem() async {
    if (menuFormKey.currentState?.validate() != true) return;
    if (selectedCategory.value == null) {
      imageError.value = 'Please select a category';
      return;
    }
    isCreatingMenuItem.value = true;
    try {
      snackbarMessageController.showSuccessMessage('Menu item created!');
    } catch (e) {
      snackbarMessageController
          .showErrorMessage('Failed to create menu item: $e');
    } finally {
      isCreatingMenuItem.value = false;
    }
  }

  // Future<MenuItem> _buildMenuItem() async {
  //   String? imagePath;
  //   if (selectedImage.value != null) {
  //     imagePath = await _storageServices.uploadImage(selectedImage.value!);
  //   }
  //   final menuItem = MenuItem(
  //     organisationId: venue!.venueID,
  //     name: menuNameController.text.trim(),
  //     category: selectedCategory.value!,
  //     description: menuDescriptionController.text.trim().isEmpty
  //         ? null
  //         : menuDescriptionController.text.trim(),
  //     imagePath: imagePath,
  //   );
  //   clearMenuForm();
  //   return menuItem;
  // }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    menuNameController.dispose();
    menuDescriptionController.dispose();
    // Add more controllers here if you add new TextEditingController fields in the future
  }

  void _showErrorMessage(String text) {
    snackbarMessageController.showErrorMessage(text);
  }
}
