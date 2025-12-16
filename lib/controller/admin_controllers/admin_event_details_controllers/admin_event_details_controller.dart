import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';

class AdminEventDetailsController {
  final VenuesController _venuesController = Get.find<VenuesController>();
  final OrganisationController _organisationController =
      Get.find<OrganisationController>();
  final Rxn<Event> event = Rxn<Event>();
  Venue? venue;
  Organisation? organisation;

  final availableMenus = <MenuModel>[].obs;
  final selectedMenu = Rxn<MenuModel>();
  final menuItems = <MenuItem>[].obs;
  final selectedMenuItemIds = <String>[].obs;
  final availableQuestionSets = <QuestionSet>[].obs;
  final selectedDemographicSetId = RxnString();
  final isLoading = true.obs;
  final isMenusLoading = true.obs;
  final isItemsLoading = true.obs;
  final FirestoreServices firestore = FirestoreServices();
  String _eventDocId = '';
  String get eventDocId => _eventDocId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _eventSubscription;

  AdminEventDetailsController();

  @visibleForTesting
  void setEventDocIdForTest(String id) => _eventDocId = id;

  void dispose() {
    _eventSubscription?.cancel();
  }

  Future<void> _writeResponseAudit(Map<String, dynamic> payload) async {
    if (_eventDocId.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection('events')
        .doc(_eventDocId)
        .collection('guestResponses') // changed here
        .doc();
    payload['createdAt'] = FieldValue.serverTimestamp();
    payload['actorUserId'] = FirebaseAuth.instance.currentUser?.uid;
    await ref.set(payload);
  }

  /// Simple confirm dialog used across this page
  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return res == true;
  }

  /// ========= LOAD EVENT + REALTIME LISTENER =========

  Future<void> loadEvent(String publicEventId) async {
    isLoading.value = true;
    try {
      // 1) Find the Firestore document by eventId field
      final snap = await firestore.eventsRef
          .where('eventId', isEqualTo: publicEventId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('No event document found for eventId: $publicEventId');
        event.value = null;
        return;
      }

      final doc = snap.docs.first;

      // Firestore document ID
      _eventDocId = doc.id;

      // initial load
      event.value = Event.fromFirestore(doc);

      // 2) Load related data
      await _loadVenue(event.value!.venueId);
      await _loadOrganisation(event.value!.organisationId);
      await _loadAvailableMenus();
      debugPrint('Current user at load: ${FirebaseAuth.instance.currentUser}');
      try {
        await _loadAvailableDemographicQuestionSets();
      } catch (e, st) {
        debugPrint('error loading demo sets in loadEvent: $e\n$st');
      }

      // 3) Sync menu + items locally
      final selMenuId = _getEventSelectedMenuId();
      if (selMenuId != null && selMenuId.isNotEmpty) {
        await _setSelectedMenuById(selMenuId, persist: false);
      } else {
        selectedMenu.value = null;
        menuItems.clear();
        selectedMenuItemIds.clear();
      }

      final selItemIds = _getEventSelectedItemIds();
      if (selItemIds != null) {
        selectedMenuItemIds.assignAll(List<String>.from(selItemIds));
      }

      // 4) Demographic selection
      selectedDemographicSetId.value =
          event.value?.selectedDemographicQuestionSetId;

      // 5) Realtime listener
      _eventSubscription?.cancel();
      _eventSubscription = firestore.eventsRef
          .doc(_eventDocId)
          .snapshots()
          .listen((docSnap) async {
        if (!docSnap.exists) return;

        event.value = Event.fromFirestore(docSnap);
        selectedDemographicSetId.value =
            event.value?.selectedDemographicQuestionSetId;

        final remoteMenuId = _getEventSelectedMenuId();
        if (remoteMenuId != null && remoteMenuId.isNotEmpty) {
          if (selectedMenu.value?.id != remoteMenuId) {
            await _setSelectedMenuById(remoteMenuId, persist: false);
          }
        } else {
          selectedMenu.value = null;
          menuItems.clear();
        }

        selectedMenuItemIds.assignAll(event.value?.selectedMenuItemIds ?? []);
        selectedMenuItemIds.refresh();
      }, onError: (e) {
        debugPrint('Event subscription error: $e');
      });
    } catch (e, st) {
      debugPrint('loadEvent error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAvailableDemographicQuestionSets() async {
    print("It's coming");
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Auth not ready / no user — keep sets empty and bail out.
        debugPrint(
            '_loadAvailableDemographicQuestionSets: no authenticated user available');
        availableQuestionSets.clear();
        return;
      }

      final uid = user.uid;
      final snap = await FirebaseFirestore.instance
          .collection('demographicQuestionSets')
          .where('userId', isEqualTo: uid)
          .where('isDisabled', isEqualTo: false)
          .get();

      final list = <QuestionSet>[];
      for (final d in snap.docs) {
        try {
          final qs =
              QuestionSet.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>);
          if (qs.questionSetId.trim().isEmpty) {
            debugPrint(
                'Skipping demographicQuestionSet ${d.id}: missing questionSetId');
            continue;
          }
          list.add(qs);
        } catch (e, st) {
          debugPrint('QuestionSet.fromDoc failed for doc ${d.id}: $e\n$st');
        }
      }
      availableQuestionSets.assignAll(list);
    } catch (e, st) {
      debugPrint("Error loading demographic sets: $e\n$st");
      availableQuestionSets.clear();
    }
  }

  Future<void> _loadVenue(String venueId) async {
    try {
      venue = await _venuesController.fetchVenueById(venueId);
    } catch (e) {
      debugPrint('Error loading venue: $e');
      venue = null;
    }
  }

  Future<void> _loadOrganisation(String organisationId) async {
    try {
      organisation = _organisationController.getOrganisation();
    } catch (e) {
      debugPrint('Error loading organisation: $e');
      organisation = null;
    }
  }

  String? _getEventSelectedMenuId() {
    final e = event.value;
    if (e == null) return null;
    if (e.selectedMenuId != null && e.selectedMenuId!.isNotEmpty) {
      return e.selectedMenuId;
    }
    final list = e.selectedMenus;
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  List<String>? _getEventSelectedItemIds() {
    final e = event.value;
    return e?.selectedMenuItemIds;
  }

  Future<void> _loadAvailableMenus() async {
    isMenusLoading.value = true;
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('menus');
      if (organisation?.organisationId != null &&
          organisation!.organisationId!.isNotEmpty) {
        q = q.where('organisationId', isEqualTo: organisation!.organisationId);
      }
      final snap = await q.orderBy('createdAt', descending: true).get();
      final list = snap.docs
          .map((d) => MenuModel.fromFirestore(d.data(), d.id))
          .toList();
      availableMenus.assignAll(list);
    } catch (e) {
      debugPrint('Error loading menus: $e');
      availableMenus.clear();
    } finally {
      isMenusLoading.value = false;
    }
  }

  Future<void> _setSelectedMenuById(String menuId,
      {bool persist = true}) async {
    if (menuId.isEmpty) {
      selectedMenu.value = null;
      menuItems.clear();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('menus')
          .doc(menuId)
          .get();
      if (!doc.exists) {
        selectedMenu.value = null;
        menuItems.clear();
        return;
      }
      final menu = MenuModel.fromFirestore(doc.data()!, doc.id);
      selectedMenu.value = menu;
      await _loadMenuItems(menu.id);

      if (persist) {
        await _persistSelectedMenu(menu.id);
      }
    } catch (e) {
      debugPrint('Error setting selected menu: $e');
    }
  }

  Future<void> selectMenu(String menuId) async {
    await _setSelectedMenuById(menuId);
  }

  Future<void> _loadMenuItems(String menuId) async {
    isItemsLoading.value = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('menu_items')
          .where('menuId', isEqualTo: menuId)
          .orderBy('category')
          .orderBy('createdAt', descending: false)
          .get();
      final list =
          snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();
      menuItems.assignAll(list);
    } catch (e) {
      debugPrint('Error loading menu items: $e');
      menuItems.clear();
    } finally {
      isItemsLoading.value = false;
    }
  }

  /// Used only by the popup – does NOT touch reactive state
  Future<List<MenuItem>> fetchMenuItemsForMenu(String menuId) async {
    final snap = await FirebaseFirestore.instance
        .collection('menu_items')
        .where('menuId', isEqualTo: menuId)
        .orderBy('category')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs
        .map((d) => MenuItem.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<void> _persistSelectedMenu(String menuId) async {
    if (event.value == null) return;
    try {
      await firestore.chooseMenuForEvent(_eventDocId, menuId);
      selectedMenuItemIds.clear();
      selectedMenuItemIds.refresh();
    } catch (e) {
      debugPrint('Error persisting selected menu: $e');
    }
  }

  /// ========= MENU: APPLY SELECTION FROM POPUP =========

  Future<void> applyMenuSelection(
      String menuId, List<String> newItemIds) async {
    if (_eventDocId.isEmpty) return;

    final previousMenuId = _getEventSelectedMenuId();
    final previousItemIds = List<String>.from(selectedMenuItemIds);

    try {
      // 1) Update menu if changed
      if (previousMenuId != menuId) {
        await firestore.chooseMenuForEvent(_eventDocId, menuId);
      }

      // 2) Remove items that were previously selected but are not anymore
      for (final oldId in previousItemIds) {
        if (!newItemIds.contains(oldId)) {
          await firestore.removeMenuItemFromEvent(
            _eventDocId,
            oldId,
            menuId: menuId,
          );
        }
      }

      // 3) Add new items
      for (final newId in newItemIds) {
        if (!previousItemIds.contains(newId)) {
          await firestore.addMenuItemToEvent(
            _eventDocId,
            newId,
            menuId: menuId,
          );
        }
      }

      // 4) Local reactive update
      selectedMenuItemIds.assignAll(newItemIds);
      selectedMenuItemIds.refresh();
      await _setSelectedMenuById(menuId, persist: false);
    } catch (e, st) {
      debugPrint('applyMenuSelection error: $e\n$st');
    }
  }

  Future<void> toggleDemographicSet(
      BuildContext context, String questionSetId) async {
    if (_eventDocId.isEmpty) {
      debugPrint('toggleDemographicSet: _eventDocId is empty');
      return;
    }

    final currentlySelected = selectedDemographicSetId.value;

    // Unselect
    if (currentlySelected != null && currentlySelected == questionSetId) {
      final confirmed = await _confirmDialog(
        context,
        title: 'Remove selection?',
        message: 'Do you want to remove the selected demographic question set?',
      );
      if (!confirmed) return;

      try {
        await firestore.updateEventFields(_eventDocId, {
          'selectedDemographicQuestionSetId': FieldValue.delete(),
        });

        await firestore.writeResponseAudit(_eventDocId, {
          'type': 'demographic_unselected',
          'questionSetId': questionSetId,
        });

        selectedDemographicSetId.value = null;
        if (event.value != null) {
          event.value =
              event.value!.copyWith(selectedDemographicQuestionSetId: null);
        }
      } catch (e, st) {
        debugPrint('Error unselecting demographic set: $e\n$st');
      }

      return;
    }

    // Select
    try {
      selectedDemographicSetId.value = questionSetId;
      if (event.value != null) {
        event.value = event.value!
            .copyWith(selectedDemographicQuestionSetId: questionSetId);
      }
      await firestore.chooseDemographicSetForEvent(_eventDocId, questionSetId);
    } catch (e, st) {
      debugPrint('Error choosing demographic set: $e\n$st');
      selectedDemographicSetId.value =
          event.value?.selectedDemographicQuestionSetId;
    }
  }

  Future<void> updateEventCoreDetails({
    required String name,
    required String serviceType, // e.g. 'buffet' or 'plated'
    String? address,
  }) async {
    if (_eventDocId.isEmpty) return;

    final payload = <String, dynamic>{
      'name': name,
      'serviceType': serviceType,
      'address': address,
    };

    try {
      // persist raw values (strings) to Firestore
      await firestore.updateEventFields(_eventDocId, payload);

      await _writeResponseAudit({
        'type': 'event_core_updated',
        'payload': payload,
      });

      // Convert serviceType string to enum for the local Event model
      final ServiceType parsedServiceType = ServiceType.values.firstWhere(
        (e) => e.name == serviceType,
        orElse: () => ServiceType.buffet,
      );

      if (event.value != null) {
        event.value = event.value!.copyWith(
          name: name,
          address: address ?? event.value!.address,
          serviceType: parsedServiceType,
        );
      }
    } catch (e, st) {
      debugPrint('updateEventCoreDetails error: $e\n$st');
    }
  }

  Future<void> chooseDemographicSet(String? questionSetId) async {
    // Defensive guards
    if (questionSetId == null || questionSetId.isEmpty) {
      debugPrint('chooseDemographicSet: invalid questionSetId (null/empty)');
      return;
    }
    if (_eventDocId.isEmpty) {
      debugPrint('chooseDemographicSet: event document id not available yet');
      return;
    }

    final qid = questionSetId;

    // Keep oldSelected for rollback if persistence fails
    final oldSelected = selectedDemographicSetId.value;
    try {
      // optimistic update
      selectedDemographicSetId.value = qid;
      if (event.value != null) {
        event.value =
            event.value!.copyWith(selectedDemographicQuestionSetId: qid);
      }

      // persist
      await firestore.chooseDemographicSetForEvent(_eventDocId, qid);
    } catch (e, st) {
      debugPrint('Error choosing demographic set: $e\n$st');
      // rollback optimistic update
      selectedDemographicSetId.value = oldSelected;
      if (event.value != null) {
        final restoreId =
            event.value?.selectedDemographicQuestionSetId ?? oldSelected;
        event.value =
            event.value!.copyWith(selectedDemographicQuestionSetId: restoreId);
      }
    }
  }

  /// Public wrapper so UI can open the demographic picker
  void openDemographicPicker(BuildContext context) {
    _showDemographicPicker(context);
  }

  void _showDemographicPicker(BuildContext context) {
    final sets = availableQuestionSets.toList();
    if (sets.isEmpty) {
      debugPrint('_showDemographicPicker: no sets available');
      // prefer UX feedback on caller side (UI already shows "create sets" button)
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DemographicSetPickerDialog(
        sets: sets,
        onSelected: (selected) async {
          final selId = selected.questionSetId;
          if (selId.trim().isEmpty) {
            debugPrint(
                '_showDemographicPicker: selected set has no id: $selected');
            return;
          }
          await chooseDemographicSet(selId);
        },
      ),
    );
  }

  /// ========= VENUE PHOTO MANAGEMENT =========

  /// Updates the event's venueId and optionally updates venue photos
  /// @param venueId The new venue ID to assign to the event
  /// @param photoPathsToAdd List of storage paths for new photos to add
  /// @param photoPathsToRemove List of storage paths for photos to remove
  Future<void> updateEventVenueAndPhotos({
    required String venueId,
    // List<String> photoPathsToAdd = const [],
    // List<String> photoPathsToRemove = const [],
  }) async {
    if (_eventDocId.isEmpty) {
      debugPrint('updateEventVenueAndPhotos: event document id not available');
      return;
    }

    try {
      // 1. Update event's venueId
      await firestore.updateEventFields(_eventDocId, {
        'venueId': venueId,
      });

      // 2. Update the event model locally
      if (event.value != null) {
        event.value = event.value!.copyWith(venueId: venueId);
      }

      // 3. Reload venue to update UI
      await _loadVenue(venueId);


      // 4. Write audit log
      await _writeResponseAudit({
        'type': 'venue_updated',
        'venueId': venueId,
      });
    } catch (e, st) {
      debugPrint('updateEventVenueAndPhotos error: $e\n$st');
      rethrow;
    }
  }

}
