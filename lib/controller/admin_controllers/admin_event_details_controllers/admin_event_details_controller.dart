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
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';
import 'dart:math' as math;

class AdminEventDetailsController {
  final VenuesController _venuesController = Get.find<VenuesController>();
  final OrganisationController _organisationController =
      Get.find<OrganisationController>();

  final Rxn<Event> event = Rxn<Event>();
  final Rxn<Venue> venue = Rxn<Venue>();
  // Venue? venue;
  Organisation? organisation;

  /// Menus are ONLY for browsing in popup
  final availableMenus = <MenuModel>[].obs;

  /// Selected items are mixed across menus
  final selectedMenuItemIds = <String>[].obs;

  /// Cached selected item docs (for Event details card)
  final selectedMenuItems = <MenuItem>[].obs;

  /// Remember which menu user last browsed in popup (NOT persisted)
  final lastBrowsedMenuId = RxnString();

  final availableQuestionSets = <QuestionSet>[].obs;
  final selectedDemographicSetId = RxnString();

  final isLoading = true.obs;
  final isMenusLoading = true.obs;

  final FirestoreServices firestore = FirestoreServices();
  final StorageServices _storageServices = StorageServices();

  String _eventDocId = '';
  String get eventDocId => _eventDocId;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _eventSubscription;

  AdminEventDetailsController();

  FoodType? _parseFoodType(dynamic v) {
    if (v == null) return null;
    final raw = v.toString().trim();
    final last = raw.split('.').last; // handles "FoodType.nonVeg"
    final norm = last
        .replaceAll(RegExp(r'[\s_\-]'), '')
        .toLowerCase(); // non-veg/nonVeg/non veg -> nonveg
    if (norm == 'veg') return FoodType.veg;
    if (norm == 'nonveg') return FoodType.nonVeg;
    return null;
  }

  MenuItem _hydrateFoodType(MenuItem item, Map<String, dynamic> data) {
    // Prefer model value if it already exists
    final current = item.foodType;

    final fromFoodType = _parseFoodType(data['foodType']);
    final fromIsVeg = (data['isVeg'] is bool)
        ? ((data['isVeg'] as bool) ? FoodType.veg : FoodType.nonVeg)
        : null;

    final resolved = current ?? fromFoodType ?? fromIsVeg;

    if (resolved == null || current == resolved) return item;

    // MenuItem in your codebase has copyWith (you use it elsewhere)
    return item.copyWith(foodType: resolved);
  }

  @visibleForTesting
  void setEventDocIdForTest(String id) => _eventDocId = id;

  void dispose() {
    _eventSubscription?.cancel();
  }

  // =============================================================
  // LOAD EVENT + REALTIME LISTENER
  // =============================================================

  Future<void> loadEvent(String publicEventId) async {
    isLoading.value = true;
    try {
      final snap = await firestore.eventsRef
          .where('eventId', isEqualTo: publicEventId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        event.value = null;
        return;
      }

      final doc = snap.docs.first;
      _eventDocId = doc.id;

      event.value = Event.fromFirestore(doc);
      // Load event image URL (with error handling to not lose event data)
      try {
        final e = await _loadEventImageUrl(event.value!);
        print(
            'LOADED event image URL for event ID: ${e.coverImageDownloadUrl}');
        event.value = e;
        print(
            'Event after loading image URL: ${event.value!.coverImageDownloadUrl}');
      } catch (e, st) {
        debugPrint(
            'Failed to load event image URL, continuing without it: $e\n$st');
        // Event remains with the data from Firestore, just without download URL
      }

      await _loadVenue(event.value!.venueId);
      await _loadOrganisation(event.value!.organisationId);
      await _loadAvailableMenus();

      // default browse menu
      lastBrowsedMenuId.value ??=
          availableMenus.isNotEmpty ? availableMenus.first.id : null;

      try {
        await _loadAvailableDemographicQuestionSets();
      } catch (_) {}

      // ✅ load selected item ids + cache the items
      selectedMenuItemIds
          .assignAll(event.value?.selectedMenuItemIds ?? const []);
      await _refreshSelectedMenuItems(ids: selectedMenuItemIds.toList());

      selectedDemographicSetId.value =
          event.value?.selectedDemographicQuestionSetId;

      _eventSubscription?.cancel();

      // Track if this is the first snapshot (which fires immediately)
      bool isFirstSnapshot = true;

      _eventSubscription = firestore.eventsRef
          .doc(_eventDocId)
          .snapshots()
          .listen((docSnap) async {
        if (!docSnap.exists) return;

        if (isFirstSnapshot) {
          isFirstSnapshot = false;
          debugPrint(
              'Skipping initial snapshot - event already loaded with image');
          return;
        }

        final next = Event.fromFirestore(docSnap);
        event.value = next;

        selectedDemographicSetId.value = next.selectedDemographicQuestionSetId;

        final nextIds = List<String>.from(next.selectedMenuItemIds ?? const []);
        final prevIds = selectedMenuItemIds.toList();

        if (!_sameList(prevIds, nextIds)) {
          selectedMenuItemIds.assignAll(nextIds);
          selectedMenuItemIds.refresh();
          await _refreshSelectedMenuItems(ids: nextIds);
        }
      }, onError: (e) {
        debugPrint('Event subscription error: $e');
      });
    } catch (e, st) {
      debugPrint('loadEvent error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // =============================================================
  // DEMOGRAPHIC SETS
  // =============================================================

  Future<void> _loadAvailableDemographicQuestionSets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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
          if (qs.questionSetId.trim().isEmpty) continue;
          list.add(qs);
        } catch (_) {}
      }

      availableQuestionSets.assignAll(list);
    } catch (e, st) {
      debugPrint("Error loading demographic sets: $e\n$st");
      availableQuestionSets.clear();
    }
  }

  // =============================================================
  // VENUE / ORG
  // =============================================================

  Future<void> _loadVenue(String venueId) async {
    try {
      venue.value = await _venuesController.fetchVenueById(venueId);
    } catch (e) {
      debugPrint('Error loading venue: $e');
      venue.value = null;
    }
  }

  Future<void> _loadOrganisation(String organisationId) async {
    try {
      organisation = _organisationController.getOrganisation();
    } catch (_) {
      organisation = null;
    }
  }

  // =============================================================
  // MENUS (browse) + ITEMS FETCH HELPERS
  // =============================================================

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

  /// Popup browsing: items for one menu
  Future<List<MenuItem>> fetchMenuItemsForMenu(String menuId) async {
    final snap = await FirebaseFirestore.instance
        .collection('menu_items')
        .where('menuId', isEqualTo: menuId)
        .orderBy('category')
        .orderBy('createdAt', descending: false)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      final item = MenuItem.fromFirestore(data, d.id);
      return _hydrateFoodType(item, data);
    }).toList();
  }

  Future<Event> _loadEventImageUrl(Event event) async {
    try {
      // Only attempt to load if there's a path and no download URL yet
      print('Event coverImageUrl: ${event.coverImageUrl}');
      if ((event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty) ||
          (event.coverImageDownloadUrl == null ||
              event.coverImageDownloadUrl!.isEmpty)) {
        print('Loading image for event ID: ${event.eventId}');
        return await _storageServices.loadImage(event);
      }
      print('image URL is ${event.coverImageDownloadUrl}');
      return event;
    } catch (e) {
      debugPrint('Error loading event image URL: $e');
      // Return event as-is if loading fails
      return event;
    }
  }

  Future<void> updateEvent(Event updatedEvent) async {
    try {
      // Load image URL before assigning
      final eventWithImage = await _loadEventImageUrl(updatedEvent);
      event.value = eventWithImage;
      debugPrint(
          'Event updated in reactive variable: ${eventWithImage.eventId}');
    } catch (e, st) {
      debugPrint(
          'Error loading image in updateEvent, using event without image: $e\n$st');
      // Fallback: assign event without image URL if loading fails
      event.value = updatedEvent;
    }
  }

  /// ✅ Needed by popup (single id)
  Future<MenuItem?> fetchMenuItemById(String menuItemId) async {
    final id = menuItemId.trim();
    if (id.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final item = MenuItem.fromFirestore(data, doc.id);
      return _hydrateFoodType(item, data);
    } catch (e, st) {
      debugPrint('fetchMenuItemById($id) error: $e\n$st');
      return null;
    }
  }

  /// ✅ Needed by popup + event card (batch ids, preserves order)
  Future<List<MenuItem>> fetchMenuItemsByIds(List<String> menuItemIds) async {
    final ids = _normalizeIds(menuItemIds);
    if (ids.isEmpty) return const [];

    final Map<String, MenuItem> byId = {};
    const batchSize = 10;

    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.sublist(i, math.min(i + batchSize, ids.length));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('menu_items')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final d in snap.docs) {
          final data = d.data();
          final item = MenuItem.fromFirestore(data, d.id);
          byId[d.id] = _hydrateFoodType(item, data);
        }
      } catch (e, st) {
        debugPrint('fetchMenuItemsByIds batch error: $e\n$st');
      }
    }

    final out = <MenuItem>[];
    for (final id in ids) {
      final it = byId[id];
      if (it != null) out.add(it);
    }
    return out;
  }

  List<String> _normalizeIds(List<String> ids) {
    final out = <String>[];
    final seen = <String>{};
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  Future<void> _refreshSelectedMenuItems({required List<String> ids}) async {
    final cleaned = _normalizeIds(ids);
    if (cleaned.isEmpty) {
      selectedMenuItems.clear();
      selectedMenuItems.refresh();
      return;
    }

    final list = await fetchMenuItemsByIds(cleaned);
    selectedMenuItems.assignAll(list);
    selectedMenuItems.refresh();
  }

  // =============================================================
  // ✅ APPLY SELECTION (NO selectedMenuId ANYMORE)
  // =============================================================

  Future<void> applyMenuSelection(List<String> newItemIds) async {
    if (_eventDocId.isEmpty) return;

    final cleaned = _normalizeIds(newItemIds);

    // optimistic UI update
    selectedMenuItemIds.assignAll(cleaned);
    selectedMenuItemIds.refresh();
    await _refreshSelectedMenuItems(ids: cleaned);

    await firestore.updateEventFields(_eventDocId, {
      'selectedMenuItemIds': cleaned,

      // delete legacy fields
      'selectedMenuId': FieldValue.delete(),
      'selectedMenus': FieldValue.delete(),
    });
  }

  // =============================================================
  // DEMOGRAPHIC METHODS (unchanged from your existing)
  // =============================================================

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

  Future<void> toggleDemographicSet(
      BuildContext context, String questionSetId) async {
    if (_eventDocId.isEmpty) return;

    final currentlySelected = selectedDemographicSetId.value;

    if (currentlySelected != null && currentlySelected == questionSetId) {
      final confirmed = await _confirmDialog(
        context,
        title: 'Remove selection?',
        message: 'Do you want to remove the selected demographic question set?',
      );
      if (!confirmed) return;

      await firestore.updateEventFields(_eventDocId, {
        'selectedDemographicQuestionSetId': FieldValue.delete(),
      });

      selectedDemographicSetId.value = null;
      return;
    }

    selectedDemographicSetId.value = questionSetId;
    await firestore.chooseDemographicSetForEvent(_eventDocId, questionSetId);
  }

  Future<void> chooseDemographicSet(String? questionSetId) async {
    if (questionSetId == null || questionSetId.trim().isEmpty) return;
    if (_eventDocId.isEmpty) return;

    selectedDemographicSetId.value = questionSetId;
    await firestore.chooseDemographicSetForEvent(_eventDocId, questionSetId);
  }

  void openDemographicPicker(BuildContext context) {
    final sets = availableQuestionSets.toList();
    if (sets.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DemographicSetPickerDialog(
        sets: sets,
        onSelected: (selected) async {
          await chooseDemographicSet(selected.questionSetId);
        },
      ),
    );
  }

  Future<void> updateEventCoreDetails({
    required String name,
    required String serviceType,
    String? address,
  }) async {
    if (_eventDocId.isEmpty) return;

    final payload = <String, dynamic>{
      'name': name,
      'serviceType': serviceType,
      'address': address,
    };

    await firestore.updateEventFields(_eventDocId, payload);
  }

  Future<void> updateEventVenueAndPhotos({
    required String venueId,
  }) async {
    if (_eventDocId.isEmpty) return;

    await firestore.updateEventFields(_eventDocId, {
      'venueId': venueId,
    });

    if (event.value != null) {
      event.value = event.value!.copyWith(venueId: venueId);
    }

    await _loadVenue(venueId);
  }
}
