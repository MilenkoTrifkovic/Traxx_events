import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/demographic_response_model.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';

/// Controller for Guest Responses Preview page
/// Displays the guest's event, RSVP status, and allows editing responses
class GuestResponsesPreviewController extends GetxController {
  // Observable state
  final isLoading = false.obs;

  // Session controller
  final _guestSession = Get.find<GuestSessionController>();

  // 🆕 Selected guest (for companion switching)
  final Rxn<String> selectedGuestId = Rxn<String>();

  // Getters for guest and event from session
  Event? get event => _guestSession.event.value;
  GuestModel? get guest => _guestSession.guest.value;

  // 🆕 Get all guests in group (main + companions)
  List<GuestModel> get allGuests => _guestSession.groupGuests;

  final GuestFirestoreServices _firestore = GuestFirestoreServices();

  final RxMap<String, String> demographicOptionLabels = <String, String>{}.obs;
  String? _loadedDemographicSetId;

  // 🆕 Get currently selected guest (or default to session guest)

  GuestModel? get currentGuest {
    final id = selectedGuestId.value;
    if (id == null) return guest;
    return allGuests.firstWhere((g) => g.docId == id, orElse: () => guest!);
  }

  // 🆕 Check if there are companions
  bool get hasCompanions => _guestSession.hasCompanions;
  int get companionCount => _guestSession.companionCount;

  // 🆕 Check if companion editing is allowed
  /// Returns true if the main guest can edit companion responses
  /// (i.e., companions were NOT invited by email)
  bool get canEditCompanionResponses => _guestSession.canEditCompanionResponses;

  // 🔹 Getters for responses - now for selected guest
  DemographicResponseModel? get demographicsResponse {
    final guestId = selectedGuestId.value ?? guest?.guestId;
    if (guestId == null) return null;

    return _guestSession.getDemographicsResponseForGuest(guestId) ??
        _guestSession.demographicsResponse.value;
  }

  MenuSelectionResponseModel? get menuSelectionResponse {
    final guestId = selectedGuestId.value ?? guest?.guestId;
    if (guestId == null) return null;

    return _guestSession.getMenuResponseForGuest(guestId) ??
        _guestSession.menuSelectionResponse.value;
  }

  // Check if responses exist
  bool get hasDemographicsResponse => demographicsResponse != null;
  bool get hasMenuSelectionResponse => menuSelectionResponse != null;

  // Get response counts for display
  int get demographicsAnswerCount => demographicsResponse?.answers.length ?? 0;
  int get menuItemsSelectedCount => menuSelectionResponse?.selectedCount ?? 0;

  @override
  void onInit() {
    super.onInit();
    // Set default selected guest to current session guest
    selectedGuestId.value = guest?.docId;
    _loadGuestResponses();
  }

  /// 🆕 Switch to a different guest (companion)
  void selectGuest(String guestId) {
    print('👤 Switching to guest: $guestId');
    selectedGuestId.value = guestId;
  }

  Future<void> _loadDemographicOptionLabels() async {
    final resp = demographicsResponse;
    if (resp == null) return;

    final setId = (resp.demographicQuestionSetId ?? '').trim();
    if (setId.isEmpty) return;

    // cache
    if (_loadedDemographicSetId == setId &&
        demographicOptionLabels.isNotEmpty) {
      return;
    }
    _loadedDemographicSetId = setId;

    final questions = await _firestore.getDemographicQuestions(setId);
    if (questions.isEmpty) return;

    final optionsByQ = await _firestore.getDemographicOptions(
      questions.map((q) => q.id).toList(),
    );

    final map = <String, String>{};

    for (final opts in optionsByQ.values) {
      for (final o in opts) {
        if (o.label.trim().isEmpty) continue;

        // option docId -> label
        map[o.id] = o.label;

        // optional: if older data saved "value" instead of optionId
        if (o.value.trim().isNotEmpty) {
          map[o.value] = o.label;
        }
      }
    }

    demographicOptionLabels.assignAll(map);
  }

  /// Load guest responses and RSVP status
  Future<void> _loadGuestResponses() async {
    try {
      isLoading.value = true;

      print('📋 Loading responses for guest: ${guest?.name}');
      print('📅 Event: ${event?.name}');

      // If responses aren't loaded yet, trigger load from session controller
      if (!hasDemographicsResponse || !hasMenuSelectionResponse) {
        await _guestSession.loadResponses();
        await _guestSession.loadGroupGuests();
      }

      // Display loaded data
      if (hasDemographicsResponse) {
        await _loadDemographicOptionLabels();
        print('✅ Demographics: ${demographicsAnswerCount} answers found');
      } else {
        print('ℹ️ No demographics response found');
      }

      if (hasMenuSelectionResponse) {
        print('✅ Menu: ${menuItemsSelectedCount} items selected');
      } else {
        print('ℹ️ No menu selection response found');
      }
    } catch (e) {
      print('❌ Error loading guest responses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to edit RSVP response
  void editRsvpResponse(BuildContext context) {
    // TODO: Implement navigation to RSVP response page
    // Will need to create RSVP response page first
    print('📝 Edit RSVP clicked');
    print('   Guest: ${guest?.name}');
    print('   Event: ${event?.name}');
  }

  /// Navigate to edit demographics
  void editDemographics(BuildContext context) {
    final guestId = selectedGuestId.value ?? guest?.guestId;

    // Navigate to demographics edit page with selected guest ID
    print('📝 Edit demographics clicked');
    print('   Guest ID: $guestId');
    print('   Current answers: ${demographicsAnswerCount}');

    context.push(
      AppRoute.guestDemographicsEdit.path,
      extra: {'guestId': guestId},
    );
  }

  /// Navigate to edit menu selection
  void editMenuSelection(BuildContext context) {
    final guestId = selectedGuestId.value ?? guest?.guestId;

    // Navigate to menu selection edit page with selected guest ID
    print('📝 Edit menu selection clicked');
    print('   Guest ID: $guestId');
    print('   Current items: ${menuItemsSelectedCount}');

    context.push(
      AppRoute.guestMenuSelectionEdit.path,
      extra: {'guestId': guestId},
    );
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
