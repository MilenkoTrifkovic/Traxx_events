import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';

/// Controller for Guest Responses Preview page
/// Displays the guest's event, RSVP status, and allows editing responses
class GuestResponsesPreviewController extends GetxController {
  // Observable state
  final isLoading = false.obs;

  // Session controller
  final _guestSession = Get.find<GuestSessionController>();

  // Getters for guest and event from session
  Event? get event => _guestSession.event.value;
  GuestModel? get guest => _guestSession.guest.value;

  @override
  void onInit() {
    super.onInit();
    _loadGuestResponses();
  }

  /// Load guest responses and RSVP status
  Future<void> _loadGuestResponses() async {
    try {
      isLoading.value = true;

      // TODO: Fetch guest's RSVP status, demographics, and menu selections
      // from Firestore using guest.docId and event.eventId

      print('📋 Loading responses for guest: ${guest?.name}');
      print('📅 Event: ${event?.name}');

    } catch (e) {
      print('❌ Error loading guest responses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to edit RSVP response
  void editRsvpResponse() {
    // TODO: Navigate to RSVP response page
    print('Edit RSVP clicked');
  }

  /// Navigate to edit demographics
  void editDemographics() {
    // TODO: Navigate to demographics page
    print('Edit demographics clicked');
  }

  /// Navigate to edit menu selection
  void editMenuSelection() {
    // TODO: Navigate to menu selection page
    print('Edit menu selection clicked');
  }

  /// Logout guest - clears session
  /// Returns true if successful, false otherwise
  Future<bool> logout() async {
    try {
      isLoading.value = true;

      // Clear session from memory and local storage
      await _guestSession.clearSession();

      return true;

    } catch (e) {
      print('❌ Error during logout: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
