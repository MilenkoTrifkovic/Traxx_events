// import 'package:firebase_ui_auth/firebase_ui_auth.dart' hide AuthController;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganisationInfoController extends GetxController {
  // Services
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final CloudFunctionsService _cloudFunctionsService =
      Get.find<CloudFunctionsService>();
  final AuthController _authController = Get.find<AuthController>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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

  // Restaurant Info Form Controllers and Data (for NEW org path)
  final companyNameController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();

  var selectedImagePath = Rxn<String>();
  var uploadedLogoPath = Rxn<String>();
  var errorMessage = Rxn<String>();
  var shouldRedirectToDashboard = false.obs;

  // ───────────────────────────────────────────────────────────────
  // NEW: existing organisation flow
  // ───────────────────────────────────────────────────────────────

  /// true = user wants to use an existing restaurant
  /// false = user will create a new restaurant
  var useExistingOrganisation = false.obs;

  /// Simple model for existing restaurants
  final existingOrganisations = <_ExistingOrganisation>[].obs;
  var isLoadingExistingOrganisations = false.obs;
  final selectedExistingOrganisationId = RxnString();

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
  void onInit() {
    super.onInit();
    _loadExistingOrganisations();
  }

  @override
  void onClose() {
    addressController.dispose();
    cityController.dispose();
    zipController.dispose();
    companyNameController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    super.onClose();
  }

  // ───────────────────────────────────────────────────────────────
  // Existing organisations helpers
  // ───────────────────────────────────────────────────────────────

  Future<void> _loadExistingOrganisations() async {
    try {
      isLoadingExistingOrganisations.value = true;

      final snap = await _db
          .collection('organisations')
          .where('isDisabled', isEqualTo: false)
          .orderBy('name')
          .get();

      existingOrganisations.assignAll(
        snap.docs.map((d) {
          final data = d.data();

          final orgIdFromField = data['organisationId'] as String?;
          // Fallback to doc.id if the field is missing, so old data still works.
          final effectiveId =
              (orgIdFromField != null && orgIdFromField.isNotEmpty)
                  ? orgIdFromField
                  : d.id;

          return _ExistingOrganisation(
            id: effectiveId, // ✅ this is what we will store in the user document
            name: (data['name'] ?? '') as String,
            city: (data['city'] ?? '') as String,
          );
        }).toList(),
      );
    } catch (e) {
      print('❌ Error loading organisations: $e');
    } finally {
      isLoadingExistingOrganisations.value = false;
    }
  }

  void toggleUseExisting(bool value) {
    useExistingOrganisation.value = value;
  }

  void selectExistingOrganisation(String id) {
    selectedExistingOrganisationId.value = id;
  }

  // ───────────────────────────────────────────────────────────────
  // Logo selection / upload (same as before)
  // ───────────────────────────────────────────────────────────────

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

  void clearErrorMessage() {
    errorMessage.value = null;
  }

  // Step helpers (unchanged)
  int get totalSteps => steps.length;
  bool isStepCompleted(int stepIndex) => stepIndex < currentStep.value;
  bool isStepActive(int stepIndex) => stepIndex == currentStep.value;
  bool isStepPending(int stepIndex) => stepIndex > currentStep.value;

  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < totalSteps) {
      currentStep.value = stepIndex;
    }
  }

  bool get isFirstStep => currentStep.value == 0;
  bool get isLastStep => currentStep.value == totalSteps - 1;

  // ───────────────────────────────────────────────────────────────
  // Logo upload + organisation creation (NEW path for "create")
  // ───────────────────────────────────────────────────────────────

  Future<String?> _uploadImage() async {
    if (selectedImagePath.value == null) {
      return null;
    }

    try {
      print('🔄 Uploading image to Firebase Storage...');
      final imageFile = XFile(selectedImagePath.value!);
      final storagePath = await _storageServices.uploadImage(imageFile);
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
      logo: uploadedLogoPath.value,
      createdAt: DateTime.now(),
      modifiedDate: DateTime.now(),
      isDisabled: false,
    );
  }

  // ───────────────────────────────────────────────────────────────
  // NEW: attach user to an EXISTING organisation
  // ───────────────────────────────────────────────────────────────

/*   Future<void> _attachUserToExistingOrganisation(String orgId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final uid = user.uid;

    // 1️⃣ Write organisationId into the canonical user doc: /users/{uid}
    await _db.collection('users').doc(uid).set(
      {
        'organisationId': orgId,
        'modifiedDate': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2️⃣ Update AuthController memory state
    _authController.organisationId = orgId;
    _authController.setOrganisationInfoExists(true);

    // 3️⃣ Let the UI know we’re done
    shouldRedirectToDashboard.value = true;

    print('✅ Attached user $uid to organisation $orgId');
  }

  // ───────────────────────────────────────────────────────────────
  // SAVE organisation OR attach to existing
  // ───────────────────────────────────────────────────────────────

  Future<Organisation?> saveOrganisation() async {
    try {
      print('Saving organisation / attaching to existing...');
      errorMessage.value = null;

      // 1️⃣ EXISTING organisation selected
      if (useExistingOrganisation.value) {
        final selectedId = selectedExistingOrganisationId.value;
        if (selectedId == null || selectedId.isEmpty) {
          errorMessage.value = 'Please select a restaurant from the list.';
          throw Exception(errorMessage.value!);
        }

        await _attachUserToExistingOrganisation(selectedId);
        print('✅ Attached user to existing organisation: $selectedId');
        return null;
      }

      // 2️⃣ NEW organisation
      await _uploadImage();
      if (errorMessage.value != null) {
        throw Exception(errorMessage.value!);
      }

      final organisation = _createOrganisation();
      final savedOrganisation =
          await _cloudFunctionsService.saveCompanyInfo(organisation);

      print(
          'Organisation saved successfully: ${savedOrganisation.organisationId}');

      // Link user to new org using the id returned by CF
      final newOrgId = savedOrganisation.organisationId;
      if (newOrgId != null && newOrgId.isNotEmpty) {
        await _attachUserToExistingOrganisation(newOrgId);
      } else {
        print(
          '⚠️ saveCompanyInfo did not return organisationId – user not auto-linked.',
        );
      }

      return savedOrganisation;
    } catch (e) {
      print('Error saving organisation / attaching: $e');
      if (errorMessage.value == null) {
        errorMessage.value = 'Failed to save organisation: $e';
      }
      rethrow;
    }
  } */

  /*  Future<void> _attachUserToExistingOrganisation(String orgId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final uid = user.uid;

    // 1️⃣ Canonical doc: /users/{uid}
    final usersCol = _db.collection('users');
    final canonicalRef = usersCol.doc(uid);

    await canonicalRef.set(
      {
        'organisationId': orgId,
        'modifiedDate': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2️⃣ Legacy doc: the one with field userId == uid (created by CF)
    final q = await usersCol.where('userId', isEqualTo: uid).limit(1).get();
    if (q.docs.isNotEmpty) {
      await q.docs.first.reference.set(
        {
          'organisationId': orgId,
          'modifiedDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // 3️⃣ Update AuthController in memory
    _authController.organisationId = orgId;
    _authController.setOrganisationInfoExists(true);

    // 4️⃣ Let UI know we’re done
    shouldRedirectToDashboard.value = true;

    print('✅ Attached user $uid to organisation $orgId');
  } */

  Future<void> _attachUserToExistingOrganisation(String orgId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // ⬇️ This now goes through Cloud Function, not direct Firestore write
    await _cloudFunctionsService.attachUserToExistingOrganisation(orgId);

    // Update AuthController in memory
    _authController.organisationId = orgId;
    _authController.setOrganisationInfoExists(true);

    shouldRedirectToDashboard.value = true;

    print('✅ Attached user ${user.uid} to organisation $orgId');
  }

  // ───────────────────────────────────────────────────────────────
  // SAVE organisation OR attach to existing
  // ───────────────────────────────────────────────────────────────

  Future<Organisation?> saveOrganisation() async {
    try {
      print('Saving organisation / attaching to existing...');
      errorMessage.value = null;

      // 1️⃣ EXISTING organisation selected
      if (useExistingOrganisation.value) {
        final selectedId = selectedExistingOrganisationId.value;
        if (selectedId == null || selectedId.isEmpty) {
          errorMessage.value = 'Please select a restaurant from the list.';
          throw Exception(errorMessage.value!);
        }

        await _attachUserToExistingOrganisation(selectedId);
        print('✅ Attached user to existing organisation: $selectedId');
        return null;
      }

      // 2️⃣ NEW organisation
      await _uploadImage();
      if (errorMessage.value != null) {
        throw Exception(errorMessage.value!);
      }

      final organisation = _createOrganisation();
      final savedOrganisation =
          await _cloudFunctionsService.saveCompanyInfo(organisation);

      print(
          'Organisation saved successfully: ${savedOrganisation.organisationId}');

      // After saveCompanyInfo, CF already set role=admin and organisationId
      return savedOrganisation;
    } catch (e) {
      print('Error saving organisation / attaching: $e');
      if (errorMessage.value == null) {
        errorMessage.value = 'Failed to save organisation: $e';
      }
      rethrow;
    }
  }
}

/// Simple local model for existing restaurants
class _ExistingOrganisation {
  final String id;
  final String name;
  final String city;

  _ExistingOrganisation({
    required this.id,
    required this.name,
    required this.city,
  });
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
