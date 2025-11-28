import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

/// Controller for managing venue operations including creation, deletion, and form validation.
class VenueScreenController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final AuthController _authController = Get.find<AuthController>();

  // Loading states
  final isLoading = false.obs;
  final isCreatingVenue = false.obs;
  final isDeletingVenue = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Form validation
  final nameError = RxnString();
  final descriptionError = RxnString();
  final formKey = GlobalKey<FormState>();

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

  /// Creates a new venue with all required and optional parameters
  ///
  /// Required parameters:
  /// - name: The venue name
  ///
  /// Optional parameters:
  /// - description: Optional venue description
  /// - image: Optional venue photo (XFile)
  Future<Venue> createVenue({
    required String name,
    String? description,
  }) async {
    try {
      // Validate required fields
      if (name.trim().isEmpty) {
        throw Exception('Venue name is required');
      }

      final organisationId = _authController.organisationId;
      if (organisationId == null) {
        throw Exception('Organisation ID not found');
      }

      isCreatingVenue.value = true;

      // Upload image if selected
      String? photoUrl;
      if (selectedImage.value != null) {
        try {
          photoUrl = await _storageServices.uploadImage(selectedImage.value!);
          print('Image uploaded successfully: $photoUrl');
        } catch (e) {
          print('Failed to upload image: $e');
          // Continue without image - image upload is optional
        }
      }

      // Create venue object
      final venue = Venue(
        organisationId: organisationId,
        name: name.trim(),
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        photoUrl: photoUrl,
        isDisabled: false,
      );

      // Save to Firestore using the create method which handles server timestamps
      final venueId = await _firestoreServices.createVenue(venue);
      print('Venue created with ID: $venueId');

      // Refresh venues list
      // await fetchVenues();

      // Clear form
      clearForm();

      _showSuccessMessage('Venue "$name" created successfully!');
      return venue.copyWith(venueID: venueId);
    } catch (e) {
      _showErrorMessage('Failed to create venue: $e');
      throw Exception('Failed to create venue');
    } finally {
      isCreatingVenue.value = false;
    }
  }

  /// Deletes a venue by setting isDisabled to true (soft delete)
  ///
  /// Parameters:
  /// - venueID: The ID of the venue to delete
  Future<void> deleteVenue(String venueID) async {
    try {
      isDeletingVenue.value = true;

      await _firestoreServices.deleteVenue(venueID);

      // Remove from local list
      // venues.removeWhere((venue) => venue.venueID == venueID);

      _showSuccessMessage('Venue deleted successfully!');
    } catch (e) {
      _showErrorMessage('Failed to delete venue: $e');
    } finally {
      isDeletingVenue.value = false;
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

  /// Validates the venue name
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Venue name is required';
    }
    if (value.trim().length < 2) {
      return 'Venue name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Venue name must be less than 100 characters';
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

  /// Submits the form and creates the venue
  Future<Venue> submitForm() async {
    if (validateForm()) {
      final venue = await createVenue(
        name: nameController.text,
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text
            : null,
      );
      return venue;
    }
    throw Exception('Form validation failed');
  }

  /// Shows a confirmation dialog before deleting a venue
  Future<void> confirmDeleteVenue(Venue venue) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Venue'),
        content: Text(
            'Are you sure you want to delete "${venue.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && venue.venueID != null) {
      await deleteVenue(venue.venueID!);
    }
  }
}
