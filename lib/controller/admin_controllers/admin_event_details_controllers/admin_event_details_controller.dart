// imports (adjust as needed)
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
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

// --------- AdminEventDetailsController (updated) ----------
// class AdminEventDetailsController {
//   final EventsController _eventsController = Get.find<EventsController>();
//   final VenuesController _venuesController = Get.find<VenuesController>();
//   final OrganisationController _organisationController =
//       Get.find<OrganisationController>();

//   // Make event reactive so UI can rebuild on changes
//   final Rxn<Event> event = Rxn<Event>();
//   Venue? venue;
//   Organisation? organisation;

//   final availableMenus = <MenuModel>[].obs;
//   final selectedMenu = Rxn<MenuModel>();
//   final menuItems = <MenuItem>[].obs;
//   final selectedMenuItemIds = <String>[].obs;
//   final availableQuestionSets = <QuestionSet>[].obs;

//   final isLoading = true.obs;
//   final isMenusLoading = true.obs;
//   final isItemsLoading = true.obs;

//   final selectedDemographicSetId = RxnString();

//   late String _eventDocId;

//   final FirestoreServices firestore = FirestoreServices();

//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
//       _eventSubscription;

//   AdminEventDetailsController();

//   /// Dispose: cancel subscription
//   void dispose() {
//     _eventSubscription?.cancel();
//   }

//   /// Public wrapper so UI can open the demographic picker
//   void openDemographicPicker() {
//     _showDemographicPicker();
//   }

//   void _showDemographicPicker() {
//     Get.dialog(
//       DemographicSetPickerDialog(
//         sets: availableQuestionSets.toList(),
//         onSelected: (selected) async {
//           await chooseDemographicSet(selected.questionSetId);
//         },
//       ),
//       barrierDismissible: false,
//     );
//   }

//   Future<void> _writeResponseAudit(Map<String, dynamic> payload) async {
//     if (_eventDocId.isEmpty) return;
//     final ref = FirebaseFirestore.instance
//         .collection('events')
//         .doc(_eventDocId)
//         .collection('responses')
//         .doc();
//     payload['createdAt'] = FieldValue.serverTimestamp();
//     payload['actorUserId'] = FirebaseAuth.instance.currentUser?.uid;
//     await ref.set(payload);
//   }

//   /// Load event and related data (venue, org, menus, demographic sets).
//   /// Also attaches a realtime listener to the event document so UI stays in sync.
//   Future<void> loadEvent(String publicEventId) async {
//     isLoading.value = true;
//     try {
//       // 1) Find the Firestore document by eventId field
//       final snap = await firestore.eventsRef
//           .where('eventId', isEqualTo: publicEventId)
//           .limit(1)
//           .get();

//       if (snap.docs.isEmpty) {
//         debugPrint('No event document found for eventId: $publicEventId');
//         event.value = null;
//         return;
//       }

//       final doc = snap.docs.first;

//       // Firestore document ID (xAZOC...)
//       _eventDocId = doc.id;

//       // initial load into event (non-listener path)
//       event.value = Event.fromFirestore(doc);

//       // 2) Load related static-ish data (venue, org, menus, demographic sets)
//       await _loadVenue(event.value!.venueId);
//       await _loadOrganisation(event.value!.organisationId);
//       await _loadAvailableMenus();
//       await _loadAvailableDemographicQuestionSets();

//       // 3) set selected menu & items locally from event (optimistic)
//       final selMenuId = _getEventSelectedMenuId();
//       if (selMenuId != null && selMenuId.isNotEmpty) {
//         await _setSelectedMenuById(selMenuId, persist: false);
//       } else {
//         selectedMenu.value = null;
//         menuItems.clear();
//         selectedMenuItemIds.clear();
//       }

//       final selItemIds = _getEventSelectedItemIds();
//       if (selItemIds != null) {
//         selectedMenuItemIds.assignAll(List<String>.from(selItemIds));
//       }

//       // 4) set demographic selection locally
//       selectedDemographicSetId.value =
//           event.value?.selectedDemographicQuestionSetId;

//       // 5) Attach realtime listener to the event document so UI receives live updates
//       _eventSubscription?.cancel();
//       _eventSubscription = firestore.eventsRef
//           .doc(_eventDocId)
//           .snapshots()
//           .listen((docSnap) async {
//         if (!docSnap.exists) return;

//         // update event model
//         event.value = Event.fromFirestore(docSnap);

//         // update reactive fields derived from event
//         selectedDemographicSetId.value =
//             event.value?.selectedDemographicQuestionSetId;

//         // selected menu id & selected items should come from event doc
//         final remoteMenuId = _getEventSelectedMenuId();
//         if (remoteMenuId != null && remoteMenuId.isNotEmpty) {
//           // load menu & items for this menu if different from current
//           if (selectedMenu.value?.id != remoteMenuId) {
//             await _setSelectedMenuById(remoteMenuId, persist: false);
//           }
//         } else {
//           // if remote clears selected menu
//           selectedMenu.value = null;
//           menuItems.clear();
//         }

//         // sync selected menu item ids
//         selectedMenuItemIds.assignAll(event.value?.selectedMenuItemIds ?? []);
//         selectedMenuItemIds.refresh();
//       }, onError: (e) {
//         debugPrint('Event subscription error: $e');
//       });
//     } catch (e, st) {
//       debugPrint('loadEvent error: $e\n$st');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> _loadAvailableDemographicQuestionSets() async {
//     try {
//       final uid = FirebaseAuth.instance.currentUser!.uid;
//       final snap = await FirebaseFirestore.instance
//           .collection('demographicQuestionSets')
//           .where('userId', isEqualTo: uid)
//           .where('isDisabled', isEqualTo: false)
//           .get();

//       final list = snap.docs.map((d) => QuestionSet.fromDoc(d)).toList();
//       availableQuestionSets.assignAll(list);
//     } catch (e) {
//       debugPrint("Error loading demographic sets: $e");
//       availableQuestionSets.clear();
//     }
//   }

//   Future<void> _loadVenue(String venueId) async {
//     try {
//       venue = await _venuesController.fetchVenueById(venueId);
//     } catch (e) {
//       debugPrint('Error loading venue: $e');
//       venue = null;
//     }
//   }

//   Future<void> _loadOrganisation(String organisationId) async {
//     try {
//       organisation = _organisationController.getOrganisation();
//     } catch (e) {
//       debugPrint('Error loading organisation: $e');
//       organisation = null;
//     }
//   }

//   String? _getEventSelectedMenuId() {
//     final e = event.value;
//     if (e == null) return null;
//     if (e.selectedMenuId != null && e.selectedMenuId!.isNotEmpty) {
//       return e.selectedMenuId;
//     }
//     final list = e.selectedMenus;
//     if (list != null && list.isNotEmpty) {
//       return list.first;
//     }
//     return null;
//   }

//   List<String>? _getEventSelectedItemIds() {
//     final e = event.value;
//     return e?.selectedMenuItemIds;
//   }

//   Future<void> _loadAvailableMenus() async {
//     isMenusLoading.value = true;
//     try {
//       Query<Map<String, dynamic>> q =
//           FirebaseFirestore.instance.collection('menus');
//       if (organisation?.organisationId != null &&
//           organisation!.organisationId!.isNotEmpty) {
//         q = q.where('organisationId', isEqualTo: organisation!.organisationId);
//       }
//       final snap = await q.orderBy('createdAt', descending: true).get();
//       final list = snap.docs
//           .map((d) => MenuModel.fromFirestore(d.data(), d.id))
//           .toList();
//       availableMenus.assignAll(list);
//     } catch (e) {
//       debugPrint('Error loading menus: $e');
//       availableMenus.clear();
//     } finally {
//       isMenusLoading.value = false;
//     }
//   }

//   Future<void> _setSelectedMenuById(String menuId,
//       {bool persist = true}) async {
//     if (menuId.isEmpty) {
//       selectedMenu.value = null;
//       menuItems.clear();
//       return;
//     }

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('menus')
//           .doc(menuId)
//           .get();
//       if (!doc.exists) {
//         selectedMenu.value = null;
//         menuItems.clear();
//         return;
//       }
//       final menu = MenuModel.fromFirestore(doc.data()!, doc.id);
//       selectedMenu.value = menu;
//       await _loadMenuItems(menu.id);

//       if (persist) {
//         await _persistSelectedMenu(menu.id);
//       }
//     } catch (e) {
//       debugPrint('Error setting selected menu: $e');
//     }
//   }

//   Future<void> _loadMenuItems(String menuId) async {
//     isItemsLoading.value = true;
//     try {
//       final snap = await FirebaseFirestore.instance
//           .collection('menu_items')
//           .where('menuId', isEqualTo: menuId)
//           .orderBy('category')
//           .orderBy('createdAt', descending: false)
//           .get();
//       final list =
//           snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();
//       menuItems.assignAll(list);
//     } catch (e) {
//       debugPrint('Error loading menu items: $e');
//       menuItems.clear();
//     } finally {
//       isItemsLoading.value = false;
//     }
//   }

//   Future<void> _persistSelectedMenu(String menuId) async {
//     if (event.value == null) return;
//     try {
//       await firestore.chooseMenuForEvent(_eventDocId, menuId);
//       // The chooseMenuForEvent already writes audit; but also update local
//       selectedMenuItemIds.clear();
//       selectedMenuItemIds.refresh();
//     } catch (e) {
//       debugPrint('Error persisting selected menu: $e');
//     }
//   }

//   /// Called by UI when user chooses a menu from the list
//   Future<void> chooseMenu(MenuModel menu) async {
//     if (_eventDocId.isEmpty || menu.id == null) return;
//     try {
//       // optimistic local update
//       selectedMenu.value = menu;
//       menuItems.clear();
//       selectedMenuItemIds.clear();
//       // persist to firestore (this will be reflected back by the snapshot listener)
//       await firestore.chooseMenuForEvent(_eventDocId, menu.id!);
//       // load items for UI
//       await _loadMenuItems(menu.id!);
//     } catch (e) {
//       debugPrint('Error choosing menu: $e');
//       // optionally rollback optimistic change if needed
//     }
//   }

//   /// Add a menu item to the event (persist + audit)
//   Future<void> addItemToEvent(MenuItem item) async {
//     if (_eventDocId.isEmpty || item.menuItemId == null) return;
//     try {
//       // optimistic UI update
//       if (!selectedMenuItemIds.contains(item.menuItemId!)) {
//         selectedMenuItemIds.add(item.menuItemId!);
//         selectedMenuItemIds.refresh();
//       }
//       await firestore.addMenuItemToEvent(_eventDocId, item.menuItemId!,
//           menuId: selectedMenu.value?.id);
//       // snapshot listener will keep authoritative state in sync
//     } catch (e) {
//       debugPrint('Error adding item to event: $e');
//       // on failure, remove optimistic update
//       selectedMenuItemIds.removeWhere((id) => id == item.menuItemId);
//       selectedMenuItemIds.refresh();
//     }
//   }

//   /// Remove item from event (persist + audit)
//   Future<void> removeItemFromEvent(MenuItem item) async {
//     if (_eventDocId.isEmpty || item.menuItemId == null) return;
//     try {
//       // optimistic UI update
//       selectedMenuItemIds.removeWhere((id) => id == item.menuItemId);
//       selectedMenuItemIds.refresh();
//       await firestore.removeMenuItemFromEvent(_eventDocId, item.menuItemId!,
//           menuId: selectedMenu.value?.id);
//     } catch (e) {
//       debugPrint('Error removing item from event: $e');
//       // optionally restore optimistic removal on failure by re-adding the id
//       if (!selectedMenuItemIds.contains(item.menuItemId!)) {
//         selectedMenuItemIds.add(item.menuItemId!);
//         selectedMenuItemIds.refresh();
//       }
//     }
//   }

//   /// Choose demographic set (simple choose)
//   Future<void> chooseDemographicSet(String questionSetId) async {
//     if (_eventDocId.isEmpty || questionSetId.isEmpty) return;

//     try {
//       // optimistic update (so UI responds instantly)
//       selectedDemographicSetId.value = questionSetId;
//       if (event.value != null) {
//         event.value = event.value!.copyWith(
//           selectedDemographicQuestionSetId: questionSetId,
//         );
//       }

//       // persist (this also writes audit inside the FirestoreService)
//       await firestore.chooseDemographicSetForEvent(_eventDocId, questionSetId);
//     } catch (e) {
//       debugPrint('Error choosing demographic set: $e');
//       // rollback optimistic update if needed
//       selectedDemographicSetId.value =
//           event.value?.selectedDemographicQuestionSetId;
//     }
//   }

//   /// Show a confirm dialog. Returns true if user confirmed.
//   Future<bool> _confirmDialog(BuildContext context,
//       {required String title, required String message}) async {
//     final res = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.of(ctx).pop(false),
//               child: const Text('Cancel')),
//           ElevatedButton(
//               onPressed: () => Navigator.of(ctx).pop(true),
//               child: const Text('Yes')),
//         ],
//       ),
//     );
//     return res == true;
//   }

//   /// Toggle selection for demographic question set.
//   /// If already selected, ask confirm to unselect.
//   Future<void> toggleDemographicSet(
//       BuildContext context, String questionSetId) async {
//     // If the event doc id isn't set, bail out
//     if (_eventDocId.isEmpty) {
//       debugPrint('toggleDemographicSet: _eventDocId is empty; cannot proceed');
//       return;
//     }

//     final currentlySelected = selectedDemographicSetId.value;

//     // If tapped on the already selected set → ask confirmation to unselect
//     if (currentlySelected != null && currentlySelected == questionSetId) {
//       final confirmed = await _confirmDialog(
//         context,
//         title: 'Remove selection?',
//         message: 'Do you want to remove the selected demographic question set?',
//       );
//       if (!confirmed) return;

//       try {
//         // Remove the selection field from Firestore
//         await firestore.updateEventFields(_eventDocId, {
//           'selectedDemographicQuestionSetId': FieldValue.delete(),
//         });

//         await firestore.writeResponseAudit(_eventDocId, {
//           'type': 'demographic_unselected',
//           'questionSetId': questionSetId,
//         });

//         // Update reactive model + local Event instance
//         selectedDemographicSetId.value = null;
//         if (event.value != null) {
//           event.value =
//               event.value!.copyWith(selectedDemographicQuestionSetId: null);
//         }
//       } catch (e, st) {
//         debugPrint('Error unselecting demographic set: $e\n$st');
//       }

//       return;
//     }

//     // Otherwise: select the new set (optimistic + persist)
//     try {
//       selectedDemographicSetId.value = questionSetId;
//       if (event.value != null) {
//         event.value = event.value!
//             .copyWith(selectedDemographicQuestionSetId: questionSetId);
//       }
//       await firestore.chooseDemographicSetForEvent(_eventDocId, questionSetId);
//     } catch (e, st) {
//       debugPrint('Error choosing demographic set: $e\n$st');
//       // rollback
//       selectedDemographicSetId.value =
//           event.value?.selectedDemographicQuestionSetId;
//     }
//   }

//   /// Remove menu item with confirmation
//   Future<void> confirmAndRemoveMenuItem(
//       BuildContext context, MenuItem item) async {
//     final ok = await _confirmDialog(
//       context,
//       title: 'Remove menu item?',
//       message: 'Remove "${item.name}" from this event?',
//     );
//     if (!ok) return;
//     await removeItemFromEvent(item);
//   }
// }

class AdminEventDetailsController {
  final EventsController _eventsController = Get.find<EventsController>();
  final VenuesController _venuesController = Get.find<VenuesController>();
  final OrganisationController _organisationController =
      Get.find<OrganisationController>();

  /// Make event reactive so UI can rebuild on changes
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

  // backing field for the Firestore document id for this event.
  // initialize to empty string to avoid late initialization issues.
  String _eventDocId = '';
  String get eventDocId => _eventDocId;

  // Firestore helper wrapper
  final FirestoreServices firestore = FirestoreServices();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _eventSubscription;

  AdminEventDetailsController();

  /// Optional setter for special cases (tests / manual override).
  /// Use sparingly — normally the controller sets this during loadEvent().
  @visibleForTesting
  void setEventDocIdForTest(String id) => _eventDocId = id;

  void dispose() {
    _eventSubscription?.cancel();
  }

  /// ========= COMMON HELPERS =========

  Future<void> _writeResponseAudit(Map<String, dynamic> payload) async {
    if (_eventDocId.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection('events')
        .doc(_eventDocId)
        .collection('responses')
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

  /// ========= DEMOGRAPHIC SET =========

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

  /// ========= EVENT CORE DETAILS (EDIT DIALOG) =========

  /// ========= EVENT CORE DETAILS (EDIT DIALOG) =========
  ///
  /// Accepts raw values (serviceType as String, address as String?)
  /// - Writes raw values to Firestore (serviceType name, address)
  /// - Converts serviceType string to ServiceType enum for local model update
  /// - Does NOT attempt to convert address -> LatLng (geocoding required)
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
          // Event has `address` field (string) — update it.
          // Do NOT set `location` (LatLng) here because we have only an address string.
          // If you want geocoding, add a geocode step and pass a LatLng to copyWith(location: ...).
          // copyWith supports address through the `address` parameter already defined.
          address: address ?? event.value!.address,
          serviceType: parsedServiceType,
        );
      }
    } catch (e, st) {
      debugPrint('updateEventCoreDetails error: $e\n$st');
    }
  }

  /// Choose a demographic set (called from the picker dialog).
  /// Optimistic update the reactive fields, then persist to Firestore.
  /// Rolls back on failure.
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

  /// Internal method that shows the picker dialog.
  /// Uses Get.dialog (same pattern used elsewhere in your code).
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
