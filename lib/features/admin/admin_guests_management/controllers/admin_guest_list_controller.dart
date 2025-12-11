import 'package:cloud_firestore/cloud_firestore.dart';
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
  final formKey = GlobalKey<FormState>();

  // Form fields
  final name = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();

  final selectedCountry = RxnString();
  final selectedState = RxnString();
  final selectedGender = Rxn<Gender>();

  final guests = <GuestModel>[].obs;
  final filteredGuests = <GuestModel>[].obs;

  final isInitialized = false.obs;

  late String eventId;

  @override
  void onInit() {
    super.onInit();
  }

  void setEventId(String id) {
    eventId = id;
    _listenToGuestChanges();
  }

  // ---------------------------
  // Realtime listener
  // ---------------------------

  void _listenToGuestChanges() {
    FirebaseFirestore.instance
        .collection("guests")
        .where("eventId", isEqualTo: eventId)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs
          .map((d) => GuestModel.fromFirestore(d.data(), d.id))
          .toList();

      guests.assignAll(list);
      filteredGuests.assignAll(list);
      isInitialized.value = true;
    });
  }

  // ---------------------------
  // Add Guest
  // ---------------------------

  /// Returns true on success, false on failure.
  /// Create (returns true on success)
  Future<bool> submitForm() async {
    if (!validateForm()) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('guests').doc();
      final guestId = docRef.id;

      final data = <String, dynamic>{
        'guestId': guestId,
        'name': name.text.trim(),
        'email': email.text.trim(),
        'address': address.text.trim(),
        'city': city.text.trim(),
        'country': selectedCountry.value,
        'state': selectedState.value,
        'gender': selectedGender.value?.name,
        'eventId': eventId,
        'isDisabled': false,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      debugPrint('submitForm: guest created, id=$guestId');
      return true;
    } catch (e, st) {
      debugPrint('submitForm error: $e\n$st');
      return false;
    }
  }

  /// Update (returns true on success). If the document doesn't exist it will create it.
  Future<bool> updateGuest() async {
    if (!validateForm()) return false;

    if (_currentGuestId == null || _currentGuestId!.isEmpty) {
      debugPrint('updateGuest: _currentGuestId is null/empty — cannot update');
      return false;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('guests').doc(_currentGuestId);

      // Check existence
      final snapshot = await docRef.get();
      final data = <String, dynamic>{
        "name": name.text.trim(),
        "email": email.text.trim(),
        "address": address.text.trim(),
        "city": city.text.trim(),
        "country": selectedCountry.value,
        "state": selectedState.value,
        "gender": selectedGender.value?.name,
        "modifiedAt": FieldValue.serverTimestamp(),
      };

      if (snapshot.exists) {
        await docRef.update(data);
        debugPrint('updateGuest: updated existing guest id=$_currentGuestId');
      } else {
        // Document missing — create with provided id so future updates succeed
        await docRef.set({
          ...data,
          'guestId': _currentGuestId,
          'eventId': eventId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
            'updateGuest: doc not found — created new guest doc id=$_currentGuestId');
      }

      return true;
    } catch (e, st) {
      debugPrint('updateGuest error: $e\n$st');
      return false;
    }
  }

  String? _currentGuestId;

  // ---------------------------
  // Prepare form for Edit
  // ---------------------------

  void updateAllFields(GuestModel guest) {
    _currentGuestId = guest.guestId;

    // Basic string fields
    name.text = guest.name ?? '';
    email.text = guest.email ?? '';
    address.text = guest.address ?? '';
    city.text = guest.city ?? '';

    // Country / State (nullable)
    selectedCountry.value = guest.country;
    selectedState.value = guest.state;

    selectedGender.value = guest.gender;

    // // Gender: map from stored String to Gender enum safely (case-insensitive)
    // if (guest.gender != null && guest.gender!.isNotEmpty) {
    //   final genderStr = guest.gender!.toLowerCase().trim();
    //   // Try matching by enum name (case-insensitive), otherwise fallback to preferNotToSay
    //   try {
    //     selectedGender.value = Gender.values.firstWhere(
    //       (g) => g.name.toLowerCase() == genderStr,
    //       orElse: () {
    //         // Additional mapping if you saved values differently (e.g. 'male','female','other')
    //         if (genderStr == 'm' || genderStr == 'male') return Gender.male;
    //         if (genderStr == 'f' || genderStr == 'female') return Gender.female;
    //         if (genderStr == 'prefer_not_to_say' ||
    //             genderStr == 'prefernotto' ||
    //             genderStr == 'prefer not to say') {
    //           return Gender.preferNotToSay;
    //         }
    //         // Last resort fallback
    //         return Gender.preferNotToSay;
    //       },
    //     );
    //   } catch (_) {
    //     // Shouldn't reach here because of orElse, but keep defensive fallback
    //     selectedGender.value = Gender.preferNotToSay;
    //   }
    // } else {
    //   selectedGender.value = null;
    // }
  }

  // ---------------------------
  // Delete Guest
  // ---------------------------

  Future<void> deleteGuest(String guestId) async {
    await FirebaseFirestore.instance.collection("guests").doc(guestId).delete();
  }

  // ---------------------------
  // Form Validation
  // ---------------------------

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    name.clear();
    email.clear();
    address.clear();
    city.clear();

    selectedCountry.value = null;
    selectedState.value = null;
    selectedGender.value = null;

    _currentGuestId = null;
  }
}
