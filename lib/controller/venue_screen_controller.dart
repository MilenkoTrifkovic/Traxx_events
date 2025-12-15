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

/// Controller for managing venue operations including creation, deletion, and form validation.
class VenueScreenController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final AuthController _authController = Get.find<AuthController>();
  final VenuesController venuesController = Get.find<VenuesController>();

  // Loading states
  final isLoading = false.obs;
  final isCreatingVenue = false.obs;
  final isDeletingVenue = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();

  var selectedCountry = Rxn<String>();
  var selectedState = Rxn<String>();

  String? venueId;
  // var selectedCountry = 'United States'.obs;
  // var selectedState = 'California'.obs; // default state

  // Form validation
  final nameError = RxnString();
  final descriptionError = RxnString();
  final streetError = RxnString();
  final cityError = RxnString();
  final zipError = RxnString();
  final stateError = RxnString();
  final countryError = RxnString();
  final formKey = GlobalKey<FormState>();

  // Image handling - support multiple images
  final selectedImages = <XFile>[].obs;
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
    streetController.dispose();
    cityController.dispose();
    zipController.dispose();
    super.onClose();
  }

  /// Clears the current global snackbar message
  void clearMessage() {
    snackbarMessageController.clearMessage();
  }

  /// Shows an error message globally
  void _showErrorMessage(String text) {
    snackbarMessageController.showErrorMessage(text);
  }

  void updateClassFields(Venue venue) {
    nameController.text = venue.name;
    descriptionController.text = venue.description ?? '';
    streetController.text = venue.street;
    cityController.text = venue.city;
    zipController.text = venue.zip;
    selectedState.value = venue.state;
    selectedCountry.value = venue.country;
    venueId = venue.venueID;
  }

  void clearClassFields() {
    nameController.clear();
    descriptionController.clear();
    streetController.clear();
    cityController.clear();
    zipController.clear();
    selectedState.value = null;
    selectedCountry.value = null;
    venueId = null;
  }

  Future<void> updateVenue() async {
    if (validateForm()) {
      final venue = await createVenue();
      final updatedVenue = await _firestoreServices.updateVenue(venue);
      print('Venue updated with ID: ${updatedVenue.venueID}');

      clearForm();
      snackbarMessageController
          .showSuccessMessage('Venue "${venue.name}" created successfully!');

      await venuesController.updateVenue(updatedVenue);
    }
    throw Exception('Form validation failed');
  }

  /// Creates a new venue with all required and optional parameters
  ///
  /// Required parameters:
  /// - name: The venue name
  ///
  /// Optional parameters:
  /// - description: Optional venue description
  /// - image: Optional venue photo (XFile)
  Future<Venue> createVenue() async {
    try {
      // Validate required fields
      if (nameController.text.trim().isEmpty) {
        throw Exception('Venue name is required');
      }
      if (streetController.text.trim().isEmpty ||
          cityController.text.trim().isEmpty ||
          zipController.text.trim().isEmpty ||
          selectedState.value!.trim().isEmpty ||
          selectedCountry.value!.trim().isEmpty) {
        throw Exception('Complete address is required');
      }

      final organisationId = _authController.organisationId;
      if (organisationId == null) {
        throw Exception('Organisation ID not found');
      }

      isCreatingVenue.value = true;

      // Upload images if selected
      List<String>? photoPaths;
      if (selectedImages.isNotEmpty) {
        try {
          photoPaths = [];
          for (final image in selectedImages) {
            final path = await _storageServices.uploadImage(image);
            photoPaths.add(path);
            print('Image uploaded successfully: $path');
          }
        } catch (e) {
          print('Failed to upload images: $e');
          // Continue without images - image upload is optional
        }
      }

      // Create venue object
      final venue = Venue(
          organisationId: organisationId,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          photoPath: photoPaths?.isNotEmpty == true ? photoPaths!.first : null,
          photoPaths: photoPaths,
          isDisabled: false,
          street: streetController.text.trim(),
          city: cityController.text.trim(),
          zip: zipController.text.trim(),
          state: selectedState.value!.trim(),
          country: selectedCountry.value!.trim(),
          venueID: venueId);
      return venue;
    } catch (e) {
      _showErrorMessage('Failed to create venue: $e');
      throw Exception('Failed to create venue');
    } finally {
      isCreatingVenue.value = false;
    }
  }

  /// Picks multiple images from the device gallery
  Future<void> pickImages() async {
    try {
      final images = await _imageServices.pickMultipleImages();
      if (images.isNotEmpty) {
        selectedImages.addAll(images);
        imageError.value = null;
        print('${images.length} image(s) selected');
      }
    } catch (e) {
      imageError.value = 'Failed to pick images: $e';
      _showErrorMessage('Failed to pick images: $e');
    }
  }

  /// Removes a specific image from the list
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Removes all selected images
  void removeAllImages() {
    selectedImages.clear();
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

  String? validateStreet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street is required';
    }
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? validateZip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zip code is required';
    }
    return null;
  }

  String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    return null;
  }

  String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
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
    selectedImages.clear();
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
      final venue = await createVenue();
      final venueId = await _firestoreServices.createVenue(venue);
      print('Venue created with ID: $venueId');

      clearForm();
      snackbarMessageController
          .showSuccessMessage('Venue "${venue.name}" created successfully!');

      final newVenue = venue.copyWith(venueID: venueId);

      venuesController.addVenue(newVenue);
      return newVenue;
    }
    throw Exception('Form validation failed');
  }
}
