import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_item_group.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/menu_cateogory_utils.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';
import 'dart:math' as math;

class AdminEventDetailsController {
  final VenuesController _venuesController = Get.find<VenuesController>();
  final OrganisationController _organisationController =
      Get.find<OrganisationController>();

  final Rxn<Event> event = Rxn<Event>();
  final Rxn<Venue> venue = Rxn<Venue>();
  Organisation? organisation;

  /// Menus are ONLY for browsing in popup
  final availableMenus = <MenuModel>[].obs;

  /// UI: ALL selected ids (ungrouped + grouped)
  final selectedMenuItemIds = <String>[].obs;

  /// Cached selected item docs (for Event details card)
  final selectedMenuItems = <MenuItem>[].obs;

  /// Grouping config stored on event
  final menuItemGroups = <MenuItemGroup>[].obs;

  /// Remember which menu user last browsed in popup (NOT persisted)
  final lastBrowsedMenuId = RxnString();

  /// Demographic sets
  final availableQuestionSets = <QuestionSet>[].obs;
  final selectedDemographicSetId = RxnString();

  final isLoading = true.obs;
  final isMenusLoading = true.obs;

  final FirestoreServices firestore = FirestoreServices();
  final StorageServices _storageServices = StorageServices();
  final SnackbarMessageController _snackbarController =
      Get.find<SnackbarMessageController>();

  String _eventDocId = '';
  String get eventDocId => _eventDocId;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _eventSubscription;

  AdminEventDetailsController();

  // =============================================================
  // Dispose
  // =============================================================
  void dispose() {
    _eventSubscription?.cancel();
  }

  // =============================================================
  // Helpers
  // =============================================================

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

  FoodType? _parseFoodType(dynamic v) {
    if (v == null) return null;
    final raw = v.toString().trim();
    final last = raw.split('.').last;
    final norm = last.replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase();
    if (norm == 'veg') return FoodType.veg;
    if (norm == 'nonveg') return FoodType.nonVeg;
    return null;
  }

  MenuItem _hydrateFoodType(MenuItem item, Map<String, dynamic> data) {
    final current = item.foodType;

    final fromFoodType = _parseFoodType(data['foodType']);
    final fromIsVeg = (data['isVeg'] is bool)
        ? ((data['isVeg'] as bool) ? FoodType.veg : FoodType.nonVeg)
        : null;

    final resolved = current ?? fromFoodType ?? fromIsVeg;
    if (resolved == null || current == resolved) return item;

    return item.copyWith(foodType: resolved);
  }

  List<MenuItemGroup> _parseGroups(dynamic raw) {
    final list = <MenuItemGroup>[];
    if (raw is! List) return list;

    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final g = MenuItemGroup.fromMap(m);

      if (g.groupId.trim().isEmpty) continue;
      if (g.name.trim().isEmpty) continue;
      if (g.itemIds.isEmpty) continue;

      list.add(
        g.copyWith(categoryKey: normalizeCategoryKey(g.categoryKey)),
      );
    }
    return list;
  }

  /// allowedSet here is the union (ungrouped ids + group item ids)
  List<MenuItemGroup> _sanitizeGroups({
    required List<MenuItemGroup> groups,
    required Set<String> allowedSet,
  }) {
    final used = <String>{};
    final out = <MenuItemGroup>[];

    for (final g in groups) {
      final gid = g.groupId.trim();
      final name = g.name.trim();
      if (gid.isEmpty || name.isEmpty) continue;

      final cat = normalizeCategoryKey(g.categoryKey);

      final cleaned = <String>[];
      for (final id in g.itemIds) {
        final x = id.trim();
        if (x.isEmpty) continue;
        if (!allowedSet.contains(x)) continue;
        if (used.contains(x)) continue;
        used.add(x);
        cleaned.add(x);
      }

      if (cleaned.isEmpty) continue;

      out.add(g.copyWith(
        name: name,
        categoryKey: cat,
        maxPick: math.max(1, g.maxPick),
        itemIds: cleaned,
      ));
    }

    return out;
  }

  /// UI list = ungrouped first + then grouped (preserve group order)
  List<String> _composeAllIds({
    required List<String> ungroupedIds,
    required List<MenuItemGroup> groups,
  }) {
    final out = <String>[];
    final seen = <String>{};

    for (final id in ungroupedIds) {
      final x = id.trim();
      if (x.isEmpty) continue;
      if (seen.add(x)) out.add(x);
    }

    for (final g in groups) {
      for (final id in g.itemIds) {
        final x = id.trim();
        if (x.isEmpty) continue;
        if (seen.add(x)) out.add(x);
      }
    }

    return out;
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // =============================================================
  // Load Event + realtime listener (NEW SCHEMA)
  // Firestore:
  //   selectedMenuItemIds => ONLY ungrouped
  //   menuItemGroups      => grouped (radio)
  // UI:
  //   selectedMenuItemIds Rx => ALL (ungrouped + grouped)
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

      // Base event
      event.value = Event.fromFirestore(doc);

      // Optional: load cover image download URL if you use it
      try {
        event.value = await _loadEventImageUrl(event.value!);
      } catch (_) {}

      await _loadVenue(event.value!.venueId);
      await _loadOrganisation(event.value!.organisationId);
      await _loadAvailableMenusForEventOrg(event.value!.organisationId);

      lastBrowsedMenuId.value ??=
          availableMenus.isNotEmpty ? availableMenus.first.id : null;

      try {
        await _loadAvailableDemographicQuestionSets();
      } catch (_) {}

      selectedDemographicSetId.value =
          event.value?.selectedDemographicQuestionSetId;

      // NEW schema read
      final ungrouped =
          _normalizeIds(event.value?.selectedMenuItemIds ?? const <String>[]);

      final parsedGroups = _parseGroups(doc.data()['menuItemGroups']);
      final allowed = <String>{...ungrouped};
      for (final g in parsedGroups) {
        allowed.addAll(g.itemIds);
      }

      final safeGroups =
          _sanitizeGroups(groups: parsedGroups, allowedSet: allowed);
      menuItemGroups.assignAll(safeGroups);

      final allIds =
          _composeAllIds(ungroupedIds: ungrouped, groups: safeGroups);
      selectedMenuItemIds.assignAll(allIds);
      await _refreshSelectedMenuItems(ids: allIds);

      // Realtime updates
      _eventSubscription?.cancel();
      bool isFirstSnapshot = true;

      _eventSubscription = firestore.eventsRef
          .doc(_eventDocId)
          .snapshots()
          .listen((docSnap) async {
        if (!docSnap.exists) return;

        if (isFirstSnapshot) {
          isFirstSnapshot = false;
          return;
        }

        final next = Event.fromFirestore(docSnap);
        event.value = next;
        selectedDemographicSetId.value = next.selectedDemographicQuestionSetId;

        final ungrouped2 =
            _normalizeIds(next.selectedMenuItemIds ?? const <String>[]);

        final parsed2 = _parseGroups(docSnap.data()?['menuItemGroups']);
        final allowed2 = <String>{...ungrouped2};
        for (final g in parsed2) {
          allowed2.addAll(g.itemIds);
        }

        final safe2 = _sanitizeGroups(groups: parsed2, allowedSet: allowed2);
        menuItemGroups.assignAll(safe2);
        menuItemGroups.refresh();

        final all2 = _composeAllIds(ungroupedIds: ungrouped2, groups: safe2);

        if (!_sameList(selectedMenuItemIds.toList(), all2)) {
          selectedMenuItemIds.assignAll(all2);
          selectedMenuItemIds.refresh();
          await _refreshSelectedMenuItems(ids: all2);
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

  // =============================================================
  // Menus
  // =============================================================

  Future<void> _loadAvailableMenusForEventOrg(String eventOrgId) async {
    isMenusLoading.value = true;
    try {
      final orgId = eventOrgId.trim();

      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('menus');

      // ✅ Always filter by event organisation (most important fix)
      if (orgId.isNotEmpty) {
        q = q.where('organisationId', isEqualTo: orgId);
      }

      final snap = await q.get();

      // ✅ Filter disabled in code (so docs missing isDisabled also appear)
      final list = snap.docs
          .map((d) => MenuModel.fromFirestore(d.data(), d.id))
          .where((m) => m.isDisabled != true)
          .toList();

      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      availableMenus.assignAll(list);

      debugPrint('✅ Menus loaded for org=$orgId count=${list.length}');
    } catch (e, st) {
      debugPrint('❌ Error loading menus: $e\n$st');
      availableMenus.clear();
    } finally {
      isMenusLoading.value = false;
    }
  }

  Future<List<MenuItem>> fetchMenuItemsForMenu(String menuId) async {
    final snap = await FirebaseFirestore.instance
        .collection('menu_items')
        .where('menuId', isEqualTo: menuId)
        .where('isDisabled', isEqualTo: false)
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      final item = MenuItem.fromFirestore(data, d.id);
      return _hydrateFoodType(item, data);
    }).toList();

    // ✅ sort locally by category then createdAt
    list.sort((a, b) {
      final ca = normalizeCategoryKey(a.category);
      final cb = normalizeCategoryKey(b.category);
      final c = ca.compareTo(cb);
      if (c != 0) return c;

      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    });

    return list;
  }

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
  // Apply Menu Selection + Groups (NEW SCHEMA)
  // Firestore:
  //   selectedMenuItemIds => ONLY ungrouped
  //   menuItemGroups      => grouped items
  // UI:
  //   selectedMenuItemIds Rx => ALL items
  // =============================================================
  Future<void> applyMenuSelectionAndGroups({
    required List<String> newItemIds, // ALL selected ids
    required List<MenuItemGroup> groups,
  }) async {
    if (_eventDocId.isEmpty) return;

    final cleanedAll = _normalizeIds(newItemIds);
    final allSet = cleanedAll.toSet();

    final safeGroups = _sanitizeGroups(groups: groups, allowedSet: allSet);

    final groupedSet = <String>{};
    for (final g in safeGroups) {
      groupedSet.addAll(g.itemIds);
    }

    // ✅ Firestore will store ONLY ungrouped
    final ungroupedIds =
        cleanedAll.where((id) => !groupedSet.contains(id)).toList();

    // UI keeps ALL
    selectedMenuItemIds.assignAll(cleanedAll);
    selectedMenuItemIds.refresh();

    menuItemGroups.assignAll(safeGroups);
    menuItemGroups.refresh();

    await _refreshSelectedMenuItems(ids: cleanedAll);

    await firestore.updateEventFields(_eventDocId, {
      'selectedMenuItemIds': ungroupedIds,
      'menuItemGroups': safeGroups.map((g) => g.toMap()).toList(),
      'selectedMenuId': FieldValue.delete(),
      'selectedMenus': FieldValue.delete(),
    });
  }

  Future<void> applyMenuSelection(List<String> newItemIds) async {
    await applyMenuSelectionAndGroups(
      newItemIds: newItemIds,
      groups: menuItemGroups.toList(),
    );
  }

  // =============================================================
  // Demographic methods (✅ THESE FIX YOUR COMPILER ERRORS)
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
      debugPrint('Error loading demographic sets: $e\n$st');
      availableQuestionSets.clear();
    }
  }

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
    BuildContext context,
    String questionSetId,
  ) async {
    if (_eventDocId.isEmpty) return;

    final currentlySelected = selectedDemographicSetId.value;

    // Tap again = remove
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

    // Select new
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

  // =============================================================
  // Event core updates (✅ FIXES updateEventCoreDetails error)
  // =============================================================
  Future<void> updateEventCoreDetails({
    required String name,
    required String serviceType,
    required int maxInviteByGuest,
    String? address,
  }) async {
    if (_eventDocId.isEmpty) return;

    await firestore.updateEventFields(_eventDocId, {
      'name': name,
      'serviceType': serviceType,
      'maxInviteByGuest': maxInviteByGuest,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =============================================================
  // Venue / Org
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

  Future<void> updateEventVenueAndPhotos({required String venueId}) async {
    if (_eventDocId.isEmpty) return;

    await firestore.updateEventFields(_eventDocId, {
      'venueId': venueId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (event.value != null) {
      event.value = event.value!.copyWith(venueId: venueId);
    }

    await _loadVenue(venueId);
  }

  // =============================================================
  // Cover Image
  // =============================================================
  Future<Event> _loadEventImageUrl(Event e) async {
    try {
      // Only attempt if there is a path and no download URL yet
      if ((e.coverImageUrl != null && e.coverImageUrl!.isNotEmpty) &&
          (e.coverImageDownloadUrl == null ||
              e.coverImageDownloadUrl!.isEmpty)) {
        return await _storageServices.loadImage(e);
      }
      return e;
    } catch (err) {
      debugPrint('Error loading event image URL: $err');
      return e;
    }
  }

  Future<void> pickAndUploadCoverImage() async {
    if (_eventDocId.isEmpty) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      _snackbarController.showInfoMessage('Uploading cover image...');

      final storagePath = await _storageServices.uploadImage(image);

      await firestore.updateEventFields(_eventDocId, {
        'coverImageUrl': storagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final downloadUrl = await _storageServices.loadImageURL(storagePath);

      final current = event.value;
      if (current != null) {
        event.value = current.copyWith(
          coverImageUrl: storagePath,
          coverImageDownloadUrl: downloadUrl,
        );
      }

      _snackbarController
          .showSuccessMessage('Cover image uploaded successfully!');
    } catch (e, st) {
      debugPrint('Error uploading cover image: $e\n$st');
      _snackbarController.showErrorMessage('Failed to upload cover image');
      rethrow;
    }
  }
}
