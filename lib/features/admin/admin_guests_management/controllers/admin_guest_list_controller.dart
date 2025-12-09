import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class AdminGuestListController extends GetxController {
  RxList<GuestModel> guests = RxList<GuestModel>([]);
  RxList<GuestModel> filteredGuests = RxList<GuestModel>([]);
  Rx<bool> isInitialized = false.obs;

  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final EventController _eventController = Get.find<EventController>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  final email = TextEditingController();
  final name = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();

  // var selectedCountry = 'United States'.obs;
  // var selectedState = 'California'.obs; // default state
  var selectedCountry = RxnString();
  var selectedState = RxnString(); // default state
  var selectedGender = Gender.preferNotToSay.obs;

  String? guestId; // For editing existing guest

  final formKey = GlobalKey<FormState>();

  /// Validates the entire form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    return true;
  }

  Future<void> initializeGuestList() async {
    guests.clear();
    filteredGuests.clear();
    try {
      final eventId = _eventController.selectedEvent.value?.eventId;
      if (eventId == null) {
        throw Exception('Cannot load guests: No event selected.');
      }
      final fetchedGuests = await _firestoreServices.fetchGuests(eventId);
      guests.addAll(fetchedGuests);
      filteredGuests.assignAll(guests);
      // _sortGuestList();
    } finally {
      isInitialized.value = true;

      // Any finalization if needed
    }
  }

  /// Submits the form and creates the user
  Future<GuestModel> submitForm() async {
    if (validateForm()) {
      final guest = await _createGuest();
      guests.add(guest);
      filteredGuests.assignAll(guests);
      return guest;
    }
    throw Exception('Form validation failed');
  }

  Future<GuestModel> _createGuest() async {
    try {
      showLoadingIndicator();
      // Validate required fields
      if (email.text.trim().isEmpty || name.text.trim().isEmpty) {
        throw Exception('Complete address is required');
      }

      final eventId = _eventController.selectedEvent.value?.eventId;
      if (eventId == null) {
        throw Exception('Event ID not found');
      }

      // Create guest object
      final GuestModel guest = GuestModel(
        email: email.text.trim(),
        name: name.text.trim(),
        address: address.text.trim(),
        city: city.text.trim(),
        country: selectedCountry.value?.trim(),
        state: selectedState.value?.trim(),
        gender: selectedGender.value,
        eventId: eventId,
      );

      // Save to Firestore using the create method which handles server timestamps
      final createdGuest = await _firestoreServices.saveGuest(guest);
      print('Guest created with ID: ${createdGuest.guestId}');

      // Clear form
      clearForm();
      snackbarMessageController.showSuccessMessage(
          'Guest "${createdGuest.name}" created successfully!');
      // _showSuccessMessage('Venue "$name" created successfully!');

      return createdGuest;
    } catch (e) {
      snackbarMessageController.showErrorMessage('Failed to create guest: $e');
      throw Exception('Failed to create guest');
    } finally {
      hideLoadingIndicator();
      // isCreatingVenue.value = false;
    }
  }

  Future<void> deleteGuest(String guestId) async {
    try {
      showLoadingIndicator();
      await _firestoreServices.deleteGuest(guestId);
      guests.removeWhere((guest) => guest.guestId == guestId);
      filteredGuests.assignAll(guests);
      snackbarMessageController
          .showSuccessMessage('Guest deleted successfully.');
    } catch (e) {
      snackbarMessageController.showErrorMessage('Failed to delete guest: $e');
      throw Exception('Failed to delete guest');
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<void> updateAllFields(GuestModel guest) async {
    email.text = guest.email;
    name.text = guest.name;
    address.text = guest.address ?? '';
    city.text = guest.city ?? '';
    selectedCountry.value = guest.country;
    selectedState.value = guest.state;
    selectedGender.value = guest.gender ?? Gender.preferNotToSay;
    guestId = guest.guestId;
  }

  Future<void> updateGuest() async {
    try {
      showLoadingIndicator();
      // Validate required fields
      if (email.text.trim().isEmpty || name.text.trim().isEmpty) {
        throw Exception('Complete address is required');
      }

      final eventId = _eventController.selectedEvent.value?.eventId;
      if (eventId == null) {
        throw Exception('Event ID not found');
      }
      print('Updating guest with eventid: ${eventId}');

      // Create guest object
      final GuestModel guest = GuestModel(
        eventId: eventId,
        guestId: guestId,
        email: email.text.trim(),
        name: name.text.trim(),
        address: address.text.trim(),
        city: city.text.trim(),
        country: selectedCountry.value?.trim(),
        state: selectedState.value?.trim(),
        gender: selectedGender.value,
      );

      // Update guest in Firestore
      await _firestoreServices.updateGuest(guest);

      // Update local list
      final index =
          guests.indexWhere((element) => element.guestId == guest.guestId);
      if (index != -1) {
        guests[index] = guest;
        filteredGuests.assignAll(guests);
      }
      snackbarMessageController
          .showSuccessMessage('Guest updated successfully!');
    } catch (e) {
      snackbarMessageController.showErrorMessage('Failed to update guest: $e');
      throw Exception('Failed to update guest');
    } finally {
      hideLoadingIndicator();
    }
  }

  void clearForm() {
    email.clear();
    name.clear();
    address.clear();
    city.clear();
    selectedCountry.value = null;
    selectedState.value = null;
    selectedGender.value = Gender.preferNotToSay;
    guestId = null;
  }

  @override
  void onClose() {
    email.dispose();
    name.dispose();
    address.dispose();
    city.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    initializeGuestList();
  }
}
