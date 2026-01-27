import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

class MenuSelectionController extends GetxController {
  final GuestFirestoreServices _guestService;
  final CloudFunctionsService _cloudFunctions;

  MenuSelectionController({
    GuestFirestoreServices? guestService,
    CloudFunctionsService? cloudFunctions,
  })  : _guestService = guestService ?? GuestFirestoreServices(),
        _cloudFunctions = cloudFunctions ?? Get.find<CloudFunctionsService>();

  // ---------------------------------------------------------------------------
  // Observables
  // ---------------------------------------------------------------------------

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString eventName = 'Menu Selection'.obs;

  /// ✅ Ungrouped items (multi-select)
  final RxList<MenuItemDto> items = <MenuItemDto>[].obs;

  /// ✅ Grouped items (radio pick 1)
  final RxList<MenuGroupDto> groups = <MenuGroupDto>[].obs;

  /// ✅ Ungrouped selections
  final RxSet<String> selectedIds = <String>{}.obs;

  /// ✅ Group picks: groupId -> chosen itemId (radio)
  final RxMap<String, String?> groupPick = <String, String?>{}.obs;

  final Rx<Map<String, dynamic>?> invitation = Rx<Map<String, dynamic>?>(null);
  final Rx<ResponseFlowState?> flowState = Rx<ResponseFlowState?>(null);

  final RxString currentPersonName = ''.obs;
  final RxnInt companionIndex = RxnInt(null);

  // Filters (apply only to ungrouped list)
  final RxString searchQuery = ''.obs;
  final RxnBool vegFilter = RxnBool(null); // null=all, true=veg, false=non-veg

  final Rxn<DietPreference> dietPref = Rxn<DietPreference>();

  String _personKey(int? companionIdx) =>
      companionIdx == null ? 'main' : 'c$companionIdx';

  // Call from initialize() after loading invitation/menu state
  void loadDietPrefFromInvitation(
      Map<String, dynamic> invitationJson, int? companionIdx) {
    final m = (invitationJson['dietPreferenceByPerson'] as Map?)
        ?.cast<String, dynamic>();
    final raw = m?[_personKey(companionIdx)]?.toString();
    dietPref.value = DietPreferenceX.fromDb(raw);
  }

  /// Visible items (ungrouped)
  List<MenuItemDto> get dietFilteredUngrouped {
    final pref = dietPref.value;
    if (pref == null) return const [];
    return filteredItems.where((it) => matchesDiet(it, pref)).toList();
  }

  /// Helper for group card
  List<MenuItemDto> dietFilteredGroupItems(MenuGroupDto g) {
    final pref = dietPref.value;
    if (pref == null) return const [];
    return g.items.where((it) => matchesDiet(it, pref)).toList();
  }

  void _dropInvalidSelections() {
    final pref = dietPref.value;
    if (pref == null) return;

    // ✅ remove ungrouped selections that don’t match
    selectedIds.removeWhere((id) {
      final it = items.firstWhereOrNull((x) => x.id == id);
      if (it == null) return false; // keep if we can't resolve
      return !matchesDiet(it, pref);
    });
    selectedIds.refresh(); // safe for UI updates

    // ✅ clear group picks that don’t match
    final toClear = <String>[];
    groupPick.forEach((groupId, pickedId) {
      final pid = (pickedId ?? '').trim();
      if (pid.isEmpty) return;

      final it = groups
          .firstWhereOrNull((g) => g.groupId == groupId)
          ?.items
          .firstWhereOrNull((x) => x.id == pid);

      if (it != null && !matchesDiet(it, pref)) {
        toClear.add(groupId);
      }
    });

    for (final gid in toClear) {
      groupPick[gid] = null;
    }
    groupPick.refresh();
  }

  void setDietPreference(DietPreference pref) {
    dietPref.value = pref;

    // keep your existing filter aligned
    vegFilter.value =
        (pref == DietPreference.both) ? null : (pref == DietPreference.veg);

    _dropInvalidSelections();
  }

  // Future<void> setDietPreference({
  //   required DietPreference pref,
  //   required String invitationId,
  //   required int? companionIdx,
  //   bool persist = true,
  // }) async {
  //   dietPref.value = pref;

  //   vegFilter.value =
  //       (pref == DietPreference.both) ? null : (pref == DietPreference.veg);

  //   _dropInvalidSelections();

  //   // if (!persist) return;

  //   // await FirebaseFirestore.instance
  //   //     .collection('invitations')
  //   //     .doc(invitationId)
  //   //     .update({
  //   //   'dietPreferenceByPerson.${_personKey(companionIdx)}': pref.dbValue,
  //   //   'modifiedAt': FieldValue.serverTimestamp(),
  //   // });
  // }

  // ---------------------------------------------------------------------------
  // Computed Properties
  // ---------------------------------------------------------------------------

  /// Filtered ungrouped items based on search and veg filter.
  List<MenuItemDto> get filteredItems {
    var list = [...items];

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((it) {
        return it.name.toLowerCase().contains(q) ||
            it.description.toLowerCase().contains(q);
      }).toList();
    }

    if (vegFilter.value != null) {
      list = list.where((it) => it.isVeg == vegFilter.value).toList();
    }

    return list;
  }

  int get vegCount => items.where((x) => x.isVeg == true).length;
  int get nonVegCount => items.where((x) => x.isVeg == false).length;

  /// ✅ total selected count = ungrouped + group picks
  int get selectedCount => finalSelectedIds.length;

  /// ✅ final selected IDs to submit (ungrouped + chosen radio)
  List<String> get finalSelectedIds {
    final out = <String>{};

    // ungrouped selections
    out.addAll(selectedIds);

    // group picks
    for (final v in groupPick.values) {
      final id = (v ?? '').trim();
      if (id.isNotEmpty) out.add(id);
    }

    return out.toList();
  }

  /// ✅ enforce group picks before submit
  List<String> get missingGroupNames {
    final missing = <String>[];
    for (final g in groups) {
      final picked = (groupPick[g.groupId] ?? '').trim();
      if (picked.isEmpty) missing.add(g.name);
    }
    return missing;
  }

  /// Check if current person has already submitted menu.
  bool get isCurrentPersonDone {
    final inv = invitation.value;
    if (inv == null) return false;

    if (companionIndex.value == null) {
      return _guestService.isMainMenuComplete(inv);
    } else {
      final companion = _guestService.getCompanion(inv, companionIndex.value!);
      if (companion == null) return false;
      return _guestService.isCompanionMenuComplete(companion);
    }
  }

  /// Check if current person has completed demographics (prerequisite).
  bool get isDemographicsComplete {
    final inv = invitation.value;
    if (inv == null) return false;

    if (companionIndex.value == null) {
      return _guestService.isMainDemographicsComplete(inv);
    } else {
      final companion = _guestService.getCompanion(inv, companionIndex.value!);
      if (companion == null) return false;
      return _guestService.isCompanionDemographicsComplete(companion);
    }
  }

  /// Check if entire flow is complete.
  bool get isFlowComplete {
    final inv = invitation.value;
    if (inv == null) return false;
    return _guestService.isFlowComplete(inv);
  }

  /// Get total number of people (main + companions).
  int get totalPeople {
    final inv = invitation.value;
    if (inv == null) return 1;
    final companions = _guestService.getCompanions(inv);
    return 1 + companions.length;
  }

  /// Get number of completed menu submissions.
  int get completedMenuCount {
    final inv = invitation.value;
    if (inv == null) return 0;

    int count = 0;
    if (_guestService.isMainMenuComplete(inv)) count++;

    final companions = _guestService.getCompanions(inv);
    for (final c in companions) {
      if (_guestService.isCompanionMenuComplete(c)) count++;
    }

    return count;
  }

  /// Get current person number (1-based).
  int get currentPersonNumber {
    return companionIndex.value == null ? 1 : (companionIndex.value! + 2);
  }

  /// Has companions in the invitation.
  bool get hasCompanions {
    final inv = invitation.value;
    if (inv == null) return false;
    return _guestService.getCompanions(inv).isNotEmpty;
  }

  /// Label for who we're filling for.
  String get fillingForLabel {
    if (companionIndex.value != null) {
      final name = currentPersonName.value.isNotEmpty
          ? currentPersonName.value
          : 'Companion ${companionIndex.value! + 1}';
      return 'Selecting for: $name';
    } else {
      return 'Selecting for: You';
    }
  }

  /// Dynamic button text based on flow state.
  String get buttonText {
    if (isCurrentPersonDone) return 'Continue';

    final fs = flowState.value;
    if (fs != null && !fs.isComplete) {
      final nextStep = fs.getNextStep();
      if (nextStep.step == ResponseStep.thankYou) return 'Finish';
      return 'Save & Continue';
    }

    return 'Finish';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Initialize the controller with invitation data.
  Future<void> initialize({
    required String invitationId,
    required String token,
    int? companionIdx,
  }) async {
    companionIndex.value = companionIdx;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Fetch invitation
      final inv = await _guestService.getInvitation(invitationId);
      if (inv == null) throw Exception('Invitation not found');

      // Validate token
      final validation = _guestService.validateInvitation(inv, token);
      if (!validation.isValid)
        throw Exception(validation.error ?? 'Invalid invitation');

      invitation.value = inv;
      loadDietPrefFromInvitation(inv, companionIdx);

      // Build flow state
      flowState.value = ResponseFlowState.fromInvitation(
        inv,
        token,
        invitationIdOverride: invitationId,
      );

      // Set current person name
      if (companionIdx != null) {
        final companion = _guestService.getCompanion(inv, companionIdx);
        if (companion == null) throw Exception('Invalid companion index');
        currentPersonName.value =
            _guestService.getCompanionName(companion, companionIdx);
      } else {
        currentPersonName.value = _guestService.getMainGuestName(inv);
      }

      // ✅ Load menu items + groups from Cloud Function
      final res = await _cloudFunctions.getSelectedMenuItemsForInvitation(
        invitationId: invitationId,
        token: token,
      );

      eventName.value = (res['eventName'] ?? 'Menu Selection').toString();

      // items (ungrouped)
      final rawItems = (res['items'] as List?) ?? [];
      items.value = rawItems
          .whereType<Map>()
          .map((x) => MenuItemDto.fromMap(Map<String, dynamic>.from(x)))
          .toList();

      // groups (radio)
      final rawGroups = (res['groups'] as List?) ?? [];
      groups.value = rawGroups
          .whereType<Map>()
          .map((x) => MenuGroupDto.fromMap(Map<String, dynamic>.from(x)))
          .toList();

      // reset selections
      selectedIds.clear();
      groupPick.clear();
      for (final g in groups) {
        groupPick[g.groupId] = null; // not picked yet
      }

      debugPrint(
        'MenuSelectionController: Loaded items=${items.length}, groups=${groups.length}',
      );
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('MenuSelectionController: Error loading - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load menu items only for read-only preview mode.
  /// This fetches menu items by their IDs without requiring invitation/token.
  Future<void> loadMenuItemsOnly({
    required List<String> selectedItemIds,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Preview only shows a list (no groups)
      groups.clear();
      groupPick.clear();

      final menuItems = await _guestService.getMenuItemsDirectlyByIds(
        selectedItemIds,
      );

      items.value = menuItems
          .map((x) => MenuItemDto.fromMap(Map<String, dynamic>.from(x)))
          .toList();

      selectedIds.clear();
      selectedIds.addAll(selectedItemIds);
      dietPref.value ??= DietPreference.both;

      eventName.value = 'Menu Preview';
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('MenuSelectionController: Error loading preview - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle selection of an ungrouped menu item.
  void toggleItem(String itemId) {
    if (selectedIds.contains(itemId)) {
      selectedIds.remove(itemId);
    } else {
      selectedIds.add(itemId);
    }
  }

  /// Check if an item is selected (ungrouped).
  bool isSelected(String itemId) => selectedIds.contains(itemId);

  /// ✅ Radio pick in a group (one item only)
  void pickFromGroup(String groupId, String itemId) {
    groupPick[groupId] = itemId;
    groupPick.refresh();
  }

  /// Set search query.
  void setSearchQuery(String query) => searchQuery.value = query;

  /// Set veg filter.
  void setVegFilter(bool? filter) => vegFilter.value = filter;

  /// Clear all filters.
  void clearFilters() {
    searchQuery.value = '';
    vegFilter.value = null;
  }

  /// Clear selections (when navigating to different person).
  void clearSelections() {
    selectedIds.clear();
    groupPick.clear();
    for (final g in groups) {
      groupPick[g.groupId] = null;
    }
  }

  /// Submit menu selection.
  Future<SubmitResult> submitSelection({
    required String invitationId,
    required String token,
  }) async {
    if (isSubmitting.value) {
      return SubmitResult(success: false, error: 'Already submitting');
    }

    if (isCurrentPersonDone) {
      return SubmitResult(
        success: true,
        nextStep: flowState.value?.getNextStep(),
      );
    }

    if (dietPref.value == null) {
      return SubmitResult(
          success: false, error: 'Please select Veg / Non-Veg / Both first');
    }

    // ✅ Require a pick from each group (radio)
    final missing = missingGroupNames;
    if (missing.isNotEmpty) {
      return SubmitResult(
        success: false,
        error: 'Please choose 1 item from: ${missing.join(", ")}',
      );
    }

    isSubmitting.value = true;
    errorMessage.value = '';

    try {
      await _cloudFunctions.submitMenuSelection(
        invitationId: invitationId,
        token: token,
        selectedMenuItemIds: finalSelectedIds, // ✅ combined
        companionIndex: companionIndex.value,
        dietPreference: dietPref.value!.dbValue,
      );

      _updateLocalStateAfterSubmit();

      final updatedFlowState = ResponseFlowState.fromInvitation(
        invitation.value!,
        token,
        invitationIdOverride: invitationId,
      );
      flowState.value = updatedFlowState;

      final nextStep = updatedFlowState.getNextStep();

      return SubmitResult(success: true, nextStep: nextStep);
    } catch (e) {
      errorMessage.value = e.toString();
      return SubmitResult(success: false, error: e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  NextStepInfo? getNextStep() => flowState.value?.getNextStep();

  void _updateLocalStateAfterSubmit() {
    final inv = invitation.value;
    if (inv == null) return;

    final updated = Map<String, dynamic>.from(inv);

    if (companionIndex.value == null) {
      updated['menuSelectionSubmitted'] = true;
    } else {
      final companions = _guestService.getCompanions(inv);
      if (companionIndex.value! < companions.length) {
        companions[companionIndex.value!]['menuSubmitted'] = true;
        updated['companions'] = companions;
      }
    }

    invitation.value = updated;
  }
}

/// Result of a submit operation.
class SubmitResult {
  final bool success;
  final String? error;
  final NextStepInfo? nextStep;

  SubmitResult({
    required this.success,
    this.error,
    this.nextStep,
  });
}
