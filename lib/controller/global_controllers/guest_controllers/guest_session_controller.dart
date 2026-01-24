import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/demographic_response_model.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/guest_responses_service.dart';

/// Global controller for managing guest session state
/// Handles authentication, session persistence, and guest data across the app
class GuestSessionController extends GetxController {
  // Reactive state
  final Rxn<Event> event = Rxn<Event>();
  final Rxn<GuestModel> guest = Rxn<GuestModel>();
  final isLoading = false.obs;

  // 🆕 Invitation configuration
  final Rxn<bool> isInvitingCompanionsByEmail = Rxn<bool>();

  // 🔹 Response data for current guest
  final Rxn<DemographicResponseModel> demographicsResponse =
      Rxn<DemographicResponseModel>();
  final Rxn<MenuSelectionResponseModel> menuSelectionResponse =
      Rxn<MenuSelectionResponseModel>();

  // 🆕 Group management (main guest + companions)
  final RxList<GuestModel> groupGuests = <GuestModel>[].obs;
  final RxMap<String, DemographicResponseModel> groupDemographicsResponses =
      <String, DemographicResponseModel>{}.obs;
  final RxMap<String, MenuSelectionResponseModel> groupMenuResponses =
      <String, MenuSelectionResponseModel>{}.obs;

  final RxnString _currentInvitationId = RxnString();
  final RxnString _currentToken = RxnString();

  // Services
  final _firestoreServices = FirestoreServices();
  final _responsesService = GuestResponsesService();

  // Shared preferences keys
  static const String _keyGuestId = 'guest_session_guest_id';
  static const String _keyEventId = 'guest_session_event_id';
  static const String _keyInvitationCode = 'guest_session_invitation_code';
  static const String _keyBatchId = 'guest_session_batch_id';

  String? _effectiveGuestId(GuestModel? g) {
    final gid = (g?.guestId ?? '').trim();
    if (gid.isNotEmpty) return gid;

    final did = (g?.docId ?? '').trim();
    if (did.isNotEmpty) return did;

    return null;
  }

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
  // ✅ Updated authenticate() — NO /guests reads, NO _loadInvitationConfig(), NO _findMainGuestId()
// Assumes FirestoreServices.validateGuestLogin() now queries ONLY invitations + events
// and returns:
// {
//   'event': Event,
//   'guest': GuestModel,
//   'invitationId': String,
//   'token': String,
//   'invitation': Map<String,dynamic>
// }

  Future<bool> authenticate({
    required String invitationCode,
    required String batchId,
  }) async {
    try {
      isLoading.value = true;

      final code = invitationCode.trim().toUpperCase();
      final batch = batchId.trim();

      if (code.isEmpty || batch.isEmpty) {
        return false;
      }

      final result = await _firestoreServices.validateGuestLogin(
        invitationCode: code,
        batchId: batch,
      );

      if (result == null) {
        return false;
      }

      final Event loadedEvent = result['event'] as Event;
      final GuestModel loadedGuest = result['guest'] as GuestModel;

      final String invitationId =
          (result['invitationId'] ?? '').toString().trim();
      final String token = (result['token'] ?? '').toString().trim();

      final Map<String, dynamic> inv =
          Map<String, dynamic>.from(result['invitation'] as Map);

      event.value = loadedEvent;
      guest.value = loadedGuest;

      final gid = _effectiveGuestId(loadedGuest);
      final eid = loadedEvent.eventId;

      if (gid != null && eid != null && eid.trim().isNotEmpty) {
        await _saveSession(
          guestId: gid,
          eventId: eid,
          invitationCode: code,
          batchId: batch,
        );
      }

      _currentInvitationId.value = invitationId.isEmpty ? null : invitationId;
      _currentToken.value = token.isEmpty ? null : token;

      isInvitingCompanionsByEmail.value =
          (inv['isInvitingCompanionsByEmail'] == true);

      await loadGroupGuests();

      return true;
    } catch (e, st) {
      debugPrint('❌ GuestSessionController.authenticate error: $e\n$st');
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
        return;
      }
      // Authenticate with stored credentials
      final success = await authenticate(
        invitationCode: invitationCode,
        batchId: batchId,
      );

      if (success) {
        // 🔹 Load guest responses after session is restored
        await loadResponses();

        // 🆕 Load group guests and their responses
        await loadGroupGuests();
      } else {
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

      // 🔹 Clear response data
      demographicsResponse.value = null;
      menuSelectionResponse.value = null;

      // 🆕 Clear group data
      groupGuests.clear();
      groupDemographicsResponses.clear();
      groupMenuResponses.clear();

      print('🗑️ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  /// Load guest responses from Firestore
  /// Fetches both demographic and menu selection responses
  Future<void> loadResponses() async {
    try {
      final gid = _effectiveGuestId(guest.value);
      final eventId = event.value?.eventId;

      if (gid == null || eventId == null || eventId.trim().isEmpty) {
        print('⚠️ Cannot load responses: missing guestId/docId or eventId');
        return;
      }

      print('📋 Loading responses for guest: $gid, event: $eventId');

      final results = await _responsesService.fetchAllResponses(
        guestId: gid,
        eventId: eventId,
      );

      demographicsResponse.value =
          results['demographics'] as DemographicResponseModel?;
      menuSelectionResponse.value =
          results['menuSelection'] as MenuSelectionResponseModel?;
    } catch (e) {
      print('❌ Error loading responses: $e');
    }
  }

  /// Update demographic response in Firestore and local state
  /// Returns true if successful, false otherwise
  Future<bool> updateDemographicsResponse(
      DemographicResponseModel response) async {
    try {
      print('📝 Updating demographics response...');

      await _responsesService.updateDemographicResponse(response);
      demographicsResponse.value = response;

      // 🆕 Also update in group map
      groupDemographicsResponses[response.guestId] = response;

      print('✅ Demographics response updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating demographics response: $e');
      return false;
    }
  }

  /// Update menu selection response in Firestore and local state
  /// Returns true if successful, false otherwise
  Future<bool> updateMenuSelectionResponse(
      MenuSelectionResponseModel response) async {
    try {
      print('📝 Updating menu selection response...');

      await _responsesService.updateMenuSelectionResponse(response);
      menuSelectionResponse.value = response;

      // 🆕 Also update in group map
      groupMenuResponses[response.guestId] = response;

      print('✅ Menu selection response updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating menu selection response: $e');
      return false;
    }
  }

  /// 🆕 Load all guests in the same group (main + companions)
  /// Uses groupId to fetch all related guests
  /// ONLY loads companions if isInvitingCompanionsByEmail = false
  Future<void> loadGroupGuests() async {
    try {
      final eventId = event.value?.eventId;
      final invId = _currentInvitationId.value;

      if (eventId == null || invId == null || invId.isEmpty) {
        groupGuests.value = guest.value != null ? [guest.value!] : [];
        return;
      }

      // If companions were invited by email -> companions have separate logins
      if (isInvitingCompanionsByEmail.value == true) {
        groupGuests.value = guest.value != null ? [guest.value!] : [];
        await _loadGroupResponses();
        return;
      }

      // ✅ read invitation doc (public)
      final invSnap = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(invId)
          .get();

      final inv = invSnap.data() ?? {};
      final companions = (inv['companions'] as List?) ?? const [];

      final List<GuestModel> list = [];
      if (guest.value != null) list.add(guest.value!);

      for (final c in companions) {
        if (c is! Map) continue;

        final m = Map<String, dynamic>.from(c);
        final cid = (m['guestId'] ?? '').toString().trim();
        if (cid.isEmpty) continue;

        // Build GuestModel from companion info inside invitation
        final cg = GuestModel.fromFirestore({
          'guestId': cid,
          'name': (m['guestName'] ?? '').toString(),
          'email': (m['guestEmail'] ?? '').toString(),
          'eventId': eventId,
          'isCompanion': true,
          'groupId': (m['groupId'] ?? '').toString(),
        }, cid);

        list.add(cg);
      }

      groupGuests.value = list;
      await _loadGroupResponses();
    } catch (e) {
      print('❌ Error loading group guests (invitation-based): $e');
      groupGuests.value = guest.value != null ? [guest.value!] : [];
    }
  }

  /// 🆕 Load responses for all guests in the group
  /// Private method called by loadGroupGuests
  Future<void> _loadGroupResponses() async {
    try {
      final eventId = event.value?.eventId;
      if (eventId == null) return;

      print('📦 Loading responses for ${groupGuests.length} guests');

      for (final g in groupGuests) {
        final gid = _effectiveGuestId(g);
        if (gid == null) continue;

        final results = await _responsesService.fetchAllResponses(
          guestId: gid,
          eventId: eventId,
        );

        if (results['demographics'] != null) {
          groupDemographicsResponses[gid] =
              results['demographics'] as DemographicResponseModel;
        }
        if (results['menuSelection'] != null) {
          groupMenuResponses[gid] =
              results['menuSelection'] as MenuSelectionResponseModel;
        }
      }

// Update current guest responses
      final currentId = _effectiveGuestId(this.guest.value);
      if (currentId != null) {
        demographicsResponse.value = groupDemographicsResponses[currentId];
        menuSelectionResponse.value = groupMenuResponses[currentId];
      }

      print('✅ Loaded responses for all guests in group');
    } catch (e) {
      print('❌ Error loading group responses: $e');
    }
  }

  /// 🆕 Get demographic response for a specific guest
  /// Useful for viewing companion responses
  DemographicResponseModel? getDemographicsResponseForGuest(String guestId) {
    return groupDemographicsResponses[guestId];
  }

  /// 🆕 Get menu selection response for a specific guest
  /// Useful for viewing companion responses
  MenuSelectionResponseModel? getMenuResponseForGuest(String guestId) {
    return groupMenuResponses[guestId];
  }

  /// 🆕 Check if there are companions in the group
  bool get hasCompanions => groupGuests.length > 1;

  /// 🆕 Get count of companions (excluding main guest)
  int get companionCount => groupGuests.where((g) => g.isCompanion).length;

  /// 🆕 Load invitation configuration from Firestore
  /// Fetches isInvitingCompanionsByEmail to determine if companion editing is allowed
  // Future<void> _loadInvitationConfig() async {
  //   try {
  //     final eventId = event.value?.eventId;
  //     final guestId = guest.value?.guestId;

  //     if (eventId == null || guestId == null) {
  //       print('⚠️ Cannot load invitation config: missing eventId or guestId');
  //       return;
  //     }

  //     print('📋 Loading invitation configuration...');

  //     // Find the main guest's invitation (the one who received the original invite)
  //     // If current guest is a companion, find their parent guest's invitation
  //     final mainGuestId =
  //         guest.value?.isCompanion == true ? await _findMainGuestId() : guestId;

  //     if (mainGuestId == null) {
  //       print('⚠️ Could not find main guest ID');
  //       return;
  //     }

  //     // Query invitations collection
  //     final invitationSnapshot = await FirebaseFirestore.instance
  //         .collection('invitations')
  //         .where('eventId', isEqualTo: eventId)
  //         .where('guestId', isEqualTo: mainGuestId)
  //         .limit(1)
  //         .get();

  //     if (invitationSnapshot.docs.isEmpty) {
  //       print('⚠️ No invitation found for main guest');
  //       return;
  //     }

  //     final invitationData = invitationSnapshot.docs.first.data();
  //     isInvitingCompanionsByEmail.value =
  //         invitationData['isInvitingCompanionsByEmail'] as bool?;

  //     print(
  //         '✅ Invitation config loaded: isInvitingCompanionsByEmail = ${isInvitingCompanionsByEmail.value}');
  //   } catch (e) {
  //     print('❌ Error loading invitation config: $e');
  //   }
  // }

  // /// 🆕 Find the main guest ID from the group
  // /// Returns the guestId of the non-companion guest in the group
  // Future<String?> _findMainGuestId() async {
  //   try {
  //     final groupId = guest.value?.groupId;
  //     if (groupId == null) return null;

  //     final mainGuestSnapshot = await FirebaseFirestore.instance
  //         .collection('guests')
  //         .where('groupId', isEqualTo: groupId)
  //         .where('isCompanion', isEqualTo: false)
  //         .limit(1)
  //         .get();

  //     if (mainGuestSnapshot.docs.isEmpty) return null;

  //     return mainGuestSnapshot.docs.first.data()['guestId'] as String?;
  //   } catch (e) {
  //     print('❌ Error finding main guest: $e');
  //     return null;
  //   }
  // }

  /// 🆕 Check if the main guest can edit companion responses
  /// Returns true if companions were NOT invited by email (main guest fills responses)
  bool get canEditCompanionResponses {
    // If isInvitingCompanionsByEmail is null, default to false (allow editing)
    // If true, companions must fill their own responses
    // If false, main guest fills companion responses
    return isInvitingCompanionsByEmail.value != true;
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
