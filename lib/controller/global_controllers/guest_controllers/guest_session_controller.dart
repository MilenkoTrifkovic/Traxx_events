import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';

/// Global controller for managing guest session state
/// Handles authentication, session persistence, and guest data across the app
class GuestSessionController extends GetxController {
  // Reactive state
  final Rxn<Event> event = Rxn<Event>();
  final Rxn<GuestModel> guest = Rxn<GuestModel>();
  final isLoading = false.obs;

  // Services
  final _firestoreServices = FirestoreServices();

  // Shared preferences keys
  static const String _keyGuestId = 'guest_session_guest_id';
  static const String _keyEventId = 'guest_session_event_id';
  static const String _keyInvitationCode = 'guest_session_invitation_code';
  static const String _keyBatchId = 'guest_session_batch_id';

  /// Check if guest is authenticated
  bool get isAuthenticated => guest.value != null && event.value != null;

  /// Initialize controller and restore session if exists
  /// This is called via Get.putAsync() in main.dart before router is created
  Future<GuestSessionController> init() async {
    await _restoreSession();
    return this;
  }

  /// Authenticates guest with invitation code and batch ID
  /// This method is called from:
  /// 1. Guest login controller (fresh login with invitationCode + batchId)
  /// 2. Init method during session restoration (with stored credentials)
  ///
  /// Returns true if authentication succeeds, false otherwise
  Future<bool> authenticate({
    required String invitationCode,
    required String batchId,
  }) async {
    try {
      isLoading.value = true;

      // Validate invitation code and batch ID with Firestore
      final result = await _firestoreServices.validateGuestLogin(
        invitationCode: invitationCode,
        batchId: batchId,
      );

      if (result == null) {
        print('❌ Authentication failed: Invalid credentials');
        return false;
      }

      // Extract and set event and guest
      final authenticatedEvent = result['event'] as Event;
      final authenticatedGuest = result['guest'] as GuestModel;

      event.value = authenticatedEvent;
      guest.value = authenticatedGuest;

      // Save credentials to local storage for session persistence
      await _saveSession(
        guestId: authenticatedGuest.docId,
        eventId: authenticatedEvent.eventId ?? '',
        invitationCode: invitationCode,
        batchId: batchId,
      );

      print('✅ Guest session established');
      print('   Guest: ${authenticatedGuest.name} (${authenticatedGuest.docId})');
      print('   Event: ${authenticatedEvent.name} (${authenticatedEvent.eventId})');

      return true;
    } catch (e) {
      print('❌ Authentication error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Restores session from local storage if credentials exist
  /// Called automatically during app initialization
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final invitationCode = prefs.getString(_keyInvitationCode);
      final batchId = prefs.getString(_keyBatchId);

      // Check if credentials exist in local storage
      if (invitationCode == null || batchId == null) {
        print('ℹ️ No saved session found');
        return;
      }

      print('ℹ️ Restoring guest session...');

      // Authenticate with stored credentials
      final success = await authenticate(
        invitationCode: invitationCode,
        batchId: batchId,
      );

      if (success) {
        print('✅ Session restored successfully');
      } else {
        print('❌ Session restoration failed, clearing local storage');
        await clearSession();
      }
    } catch (e) {
      print('❌ Error restoring session: $e');
      await clearSession();
    }
  }

  /// Saves session credentials to local storage
  Future<void> _saveSession({
    required String guestId,
    required String eventId,
    required String invitationCode,
    required String batchId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyGuestId, guestId);
      await prefs.setString(_keyEventId, eventId);
      await prefs.setString(_keyInvitationCode, invitationCode);
      await prefs.setString(_keyBatchId, batchId);

      print('💾 Session saved to local storage');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  /// Clears session data from memory and local storage
  /// Used for logout or when session becomes invalid
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyGuestId);
      await prefs.remove(_keyEventId);
      await prefs.remove(_keyInvitationCode);
      await prefs.remove(_keyBatchId);

      event.value = null;
      guest.value = null;

      print('🗑️ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}