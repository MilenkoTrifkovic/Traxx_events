import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/services/auth_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class SettingsScreenController extends GetxController {
  final OrganisationController organisationController =
      Get.find<OrganisationController>();
  late Organisation organisation;
  SnackbarMessageController snackbar = Get.find<SnackbarMessageController>();

  final Rxn<XFile> selectedImage = Rxn<XFile>();
  RxString currentImageUrl = ''.obs;
  // Company information controllers
  late final TextEditingController addressController;
  late final TextEditingController cityController;
  late final TextEditingController zipController;

  var selectedCountry = ''.obs;
  var selectedState = ''.obs;
  var selectedTimezone = ''.obs;
  var isEditing = false.obs;

  late final TextEditingController companyNameController;
  late final TextEditingController phoneController;
  late final TextEditingController websiteController;
  //Password change controllers
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();



  SettingsScreenController() {
    organisation = organisationController.getOrganisation()!;
    currentImageUrl.value = organisation.photoUrl ?? '';
    // Initialize controllers with values from organisation
    companyNameController = TextEditingController(text: organisation.name);
    phoneController = TextEditingController(text: organisation.phone);
    websiteController = TextEditingController(text: organisation.website);

    addressController = TextEditingController(text: organisation.street);
    cityController = TextEditingController(text: organisation.city);
    zipController = TextEditingController(text: organisation.zip);

    // Initialize Rx values
    selectedCountry.value = organisation.country;
    selectedState.value = organisation.state;
    // selectedTimezone.value = organisation.timezone;
    selectedTimezone.value = USData.timezones.firstWhere(
      (tz) => tz.split(' ').first == organisation.timezone,
      orElse: () => USData.timezones.first,
    );
  }

  /// Pick an image from gallery (or camera) and upload it to Firebase Storage.
  /// On success updates the organisation's `logo` (storage path) and
  /// `photoUrl` (download URL) locally so the UI can preview the uploaded image.
  Future<void> pickAndUploadImage(
      {ImageSource source = ImageSource.gallery}) async {
    print('Picking image from source: $source');
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source);
      selectedImage.value = picked;
      if (picked == null) return; // user cancelled

      // snackbar.showInfoMessage('Uploading image...');
      showLoadingIndicator();

      final storage = Get.find<StorageServices>();
      final path = await storage.uploadImage(picked);
      final downloadUrl = await storage.loadImageURL(path);
      currentImageUrl.value = downloadUrl ?? '';

      // update organisation in the global controller and locally
      final current = organisationController.getOrganisation();
      if (current != null) {
        final updated = current.copyWith(logo: path, photoUrl: downloadUrl);
        // organisationController.setOrganisation(updated);
        organisationController.updateOrganisation(updated);
        organisation = updated;
        snackbar.showSuccessMessage('Image uploaded');
      }
    } catch (e) {
      print('Image upload failed: $e');
      snackbar.showErrorMessage('Image upload failed');
    } finally {
      hideLoadingIndicator();
    }
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

  /// Build an updated Organisation object from the current form fields and
  /// call OrganisationController to persist it.
  /// Returns true on success, false otherwise.
  Future<void> updateOrganisation() async {
    try {
      showLoadingIndicator();
      final updated = organisation.copyWith(
        name: companyNameController.text.trim(),
        phone: phoneController.text.trim(),
        website: websiteController.text.trim(),
        street: addressController.text.trim(),
        city: cityController.text.trim(),
        zip: zipController.text.trim(),
        state: selectedState.value,
        country: selectedCountry.value,
        timezone: selectedTimezone.value,
        // Local modifiedDate - Firestore service will also set server timestamp
        modifiedDate: DateTime.now(),
      );
      // Check if any meaningful field changed compared to the current organisation.
      if (organisation.isSameAs(updated)) {
        snackbar.showInfoMessage('No changes detected');
        return;
      }

      final success = await organisationController.updateOrganisation(updated);
      if (success) {
        // update local copy as well
        organisation = updated;
        // leave editing mode after successful save
        isEditing.value = false;
        snackbar.showSuccessMessage('Organisation updated successfully');
      } else {
        snackbar.showErrorMessage('Failed to update organisation');
      }
    } catch (e) {
      print('SettingsScreenController.update error: $e');
      snackbar.showErrorMessage('Failed to update organisation');
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<void> changePassword() async {
    final current = currentPasswordController.text.trim();
    final newP = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    // Validate inputs locally first
    final curErr = ValidationHelper.validateRequired(current, 'Current password');
    if (curErr != null) {
      snackbar.showErrorMessage(curErr);
      return;
    }

    final passErr = ValidationHelper.validatePassword(newP);
    if (passErr != null) {
      snackbar.showErrorMessage(passErr);
      return;
    }

    final confirmErr = ValidationHelper.validateConfirmPassword(confirm, newP);
    if (confirmErr != null) {
      snackbar.showErrorMessage(confirmErr);
      return;
    }

    if (current == newP) {
      snackbar.showErrorMessage('New password must be different from current password');
      return;
    }

    final authServices = AuthServices();
    try {
      showLoadingIndicator();
      await authServices.changePassword(
        currentPassword: current,
        newPassword: newP,
      );
      snackbar.showSuccessMessage('Password changed successfully');
      // clear password fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      print('SettingsScreenController.changePassword error: $e');
      // Provide a generic error message; AuthServices should throw meaningful errors
      snackbar.showErrorMessage('$e');
    } finally {
      hideLoadingIndicator();
    }
  }

  /// Enter editing mode
  void startEditing() {
    isEditing.value = true;
  }

  /// Cancel editing and restore form fields from original organisation
  void cancelEditing() {
    // restore controller values
    companyNameController.text = organisation.name;
    phoneController.text = organisation.phone;
    websiteController.text = organisation.website ?? '';

    addressController.text = organisation.street;
    cityController.text = organisation.city;
    zipController.text = organisation.zip;

    selectedCountry.value = organisation.country;
    selectedState.value = organisation.state;
    selectedTimezone.value = organisation.timezone;

    isEditing.value = false;
  }
}
