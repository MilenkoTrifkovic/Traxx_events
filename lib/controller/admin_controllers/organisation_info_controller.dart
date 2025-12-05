// import 'package:firebase_ui_auth/firebase_ui_auth.dart' hide AuthController;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/models/organisation.dart';

class OrganisationInfoController extends GetxController {
  // Services
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final CloudFunctionsService _cloudFunctionsService =
      Get.find<CloudFunctionsService>();
  final AuthController _authController = Get.find<AuthController>();

  // Current active step (0-indexed)
  var currentStep = 0.obs;

  // Location & Time Form Controllers and Data
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();

  var selectedCountry = 'United States'.obs;
  var selectedState = 'California'.obs; // default state
  var selectedTimezone =
      'America/Los_Angeles (Pacific Time)'.obs; // default timezone

  // Restaurant Info Form Controllers and Data
  final companyNameController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();

  var selectedImagePath = Rxn<String>();
  var uploadedLogoPath = Rxn<String>();
  var errorMessage = Rxn<String>();
  var shouldRedirectToDashboard = false.obs;

  // List of steps with their information
  final List<StepInfo> steps = [
    StepInfo(
      icon: 'assets/icons/location.png',
      title: 'Location & Time',
      description: 'Set your business location and time',
    ),
    StepInfo(
      icon: 'assets/icons/restaurant.png',
      title: 'Restaurant Info',
      description: 'Enter your restaurant details',
    ),
  ];

  @override
  void onClose() {
    // Dispose controllers when controller is destroyed
    addressController.dispose();
    cityController.dispose();
    zipController.dispose();
    companyNameController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    super.onClose();
  }

  // Logo selection method
  Future<void> selectLogo() async {
    try {
      final XFile? pickedImage =
          await _imageServices.pickImage(ImageSource.gallery);

      if (pickedImage != null) {
        selectedImagePath.value = pickedImage.path;
        print('✅ Logo selected: ${pickedImage.path}');
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error selecting logo: $e');
      Get.snackbar(
        'Error',
        'Failed to select logo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void removeLogo() {
    selectedImagePath.value = null;
  }

  /// Clears the current error message
  void clearErrorMessage() {
    errorMessage.value = null;
  }

  // Step helpers
  int get totalSteps => steps.length;

  bool isStepCompleted(int stepIndex) => stepIndex < currentStep.value;
  bool isStepActive(int stepIndex) => stepIndex == currentStep.value;
  bool isStepPending(int stepIndex) => stepIndex > currentStep.value;

  // Go to next step
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  // Go to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  // Go to specific step
  void goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < totalSteps) {
      currentStep.value = stepIndex;
    }
  }

  bool get isFirstStep => currentStep.value == 0;
  bool get isLastStep => currentStep.value == totalSteps - 1;

  /// Uploads the selected image to Firebase Storage
  /// Returns the storage path or null if no image or upload fails
  Future<String?> _uploadImage() async {
    if (selectedImagePath.value == null) {
      return null;
    }

    try {
      print('🔄 Uploading image to Firebase Storage...');

      // Create XFile from the selected image path
      final imageFile = XFile(selectedImagePath.value!);

      // Upload image and get storage path
      final storagePath = await _storageServices.uploadImage(imageFile);

      // Store the uploaded path
      uploadedLogoPath.value = storagePath;

      print('✅ Image uploaded successfully: $storagePath');
      return storagePath;
    } catch (e) {
      print('❌ Error uploading image: $e');
      errorMessage.value = 'Failed to upload logo image. Please try again.';
      return null;
    }
  }

  String _extractTimezoneId(String timezoneValue) {
    if (timezoneValue.contains(' (')) {
      return timezoneValue.split(' (').first;
    }
    return timezoneValue;
  }

  /// Creates an Organisation instance from form data
  Organisation _createOrganisation() {
    return Organisation(
      name: companyNameController.text.trim(),
      phone: phoneController.text.trim(),
      website: websiteController.text.trim().isEmpty
          ? null
          : websiteController.text.trim(),
      street: addressController.text.trim(),
      city: cityController.text.trim(),
      zip: zipController.text.trim(),
      state: selectedState.value,
      country: selectedCountry.value,
      timezone: _extractTimezoneId(selectedTimezone.value),
      logo: uploadedLogoPath.value, // storage path
      createdAt: DateTime.now(),
      modifiedDate: DateTime.now(),
      isDisabled: false,
    );
  }

  /// Returns the saved organisation with assigned organisationId and other server fields
  Future<Organisation> saveOrganisation() async {
    try {
      print('Saving organisation through cloud function...');
      print(' shouldRedirectToDashboard is ${shouldRedirectToDashboard.value}');

      // Clear any previous error messages
      errorMessage.value = null;

      // Upload the image if one is selected
      await _uploadImage();

      // If there was an error uploading the image, don't proceed
      if (errorMessage.value != null) {
        throw Exception(errorMessage.value!);
      }

      // Create organisation object from form data
      final organisation = _createOrganisation();

      // Save through cloud function
      print('Saving organisation through Started.........');
      final savedOrganisation =
          await _cloudFunctionsService.saveCompanyInfo(organisation);
      print('Saving organisation through End.........');

      print(
          'Organisation saved successfully: ${savedOrganisation.organisationId}');

      // Let the rest of the app know that org info now exists
      _authController.setOrganisationInfoExists(true);

      // Trigger redirection to dashboard
      shouldRedirectToDashboard.value = true;
      print(' shouldRedirectToDashboard is ${shouldRedirectToDashboard.value}');

      return savedOrganisation;
    } catch (e) {
      print('Error saving organisation: $e');
      if (errorMessage.value == null) {
        errorMessage.value = 'Failed to save organisation. Please try again.';
      }
      rethrow;
    }
  }
}

class StepInfo {
  final String icon;
  final String title;
  final String description;

  StepInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
