import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

class MenusListController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final isLoading = true.obs;
  final isDeleting = false.obs; // ← NEW

  // all menu sets from `menus` collection
  final menuSets = <MenuModel>[].obs;

  // filtered menu sets (search + sort)
  final filteredMenuSets = <MenuModel>[].obs;

  final searchQuery = ''.obs;

  // remember current sort
  final currentSort = SortType.nameAZ.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMenuSets();
    ever(searchQuery, (_) => _applyFilters());
  }

  Future<void> _loadMenuSets() async {
    try {
      isLoading.value = true;

      final orgId = _authController.organisationId;
      debugPrint('MenusListController – organisationId = $orgId');

      // base collection
      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection('menus');

      // if orgId is available, filter by it; otherwise load all menus
      if (orgId != null && orgId.isNotEmpty) {
        query = query.where('organisationId', isEqualTo: orgId);
      }

      query = query.orderBy('createdAt', descending: true);

      final snap = await query.get();
      debugPrint(
          'MenusListController – menu sets fetched: ${snap.docs.length}');

      final list = snap.docs.map((doc) {
        return MenuModel.fromFirestore(doc.data(), doc.id);
      }).toList();

      menuSets.assignAll(list);
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading menu sets: $e');
      menuSets.clear();
      filteredMenuSets.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    final q = searchQuery.value.trim().toLowerCase();

    if (q.isEmpty) {
      filteredMenuSets.assignAll(menuSets);
    } else {
      filteredMenuSets.assignAll(
        menuSets.where((m) {
          final name = m.name.toLowerCase();
          final desc = (m.description ?? '').toLowerCase();
          return name.contains(q) || desc.contains(q);
        }),
      );
    }

    // re-apply current sort on filtered list
    sortMenus(currentSort.value);
  }

  void sortMenus(SortType sortType) {
    currentSort.value = sortType;
    if (filteredMenuSets.isEmpty) return;

    final list = [...filteredMenuSets];
    switch (sortType) {
      case SortType.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortType.dateNewest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case SortType.dateOldest:
        list.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
    }
    filteredMenuSets.assignAll(list);
  }

  // Called when you create a new menu set
  void addMenuSet(MenuModel newSet) {
    menuSets.insert(0, newSet);
    _applyFilters();
  }

  void removeMenuSet(String id) {
    menuSets.removeWhere((m) => m.id == id);
    _applyFilters();
  }

  /// HARD DELETE a menu set and all of its menu_items from Firestore
  Future<bool> deleteMenuSetAndItems(MenuModel menu) async {
    if (menu.id.isEmpty) return false;
    try {
      isDeleting.value = true;

      final menuId = menu.id;
      final firestore = FirebaseFirestore.instance;

      // 1) delete all menu_items where menuId == this menu.id
      final itemsSnap = await firestore
          .collection('menu_items')
          .where('menuId', isEqualTo: menuId)
          .get();

      final batch = firestore.batch();

      for (final doc in itemsSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2) delete the menu doc itself
      final menuDocRef = firestore.collection('menus').doc(menuId);
      batch.delete(menuDocRef);

      // 3) commit batch
      await batch.commit();

      // 4) update local lists
      menuSets.removeWhere((m) => m.id == menuId);
      _applyFilters();

      return true;
    } catch (e) {
      debugPrint('Error deleting menu set and items: $e');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }
}
