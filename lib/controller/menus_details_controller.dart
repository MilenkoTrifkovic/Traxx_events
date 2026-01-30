import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

class MenuSetDetailsController extends GetxController {
  final String menuId;

  MenuSetDetailsController({required this.menuId});

  final isLoading = true.obs;
  final isItemsLoading = true.obs;

  /// menus/{menuId}
  final menuSet = Rxn<MenuModel>();

  /// Raw items from Firestore
  final items = <MenuItem>[].obs;

  /// Filtered + sorted items (used by UI)
  final filteredItems = <MenuItem>[].obs;

  // ---- FILTER STATE ----
  final searchQuery = ''.obs;
  final selectedCategory = RxnString(); // Changed from MenuCategory to String
  final minPrice = RxnDouble();
  final maxPrice = RxnDouble();

  // ---- SORT STATE ----
  final sortType = MenuItemsSortType.nameAZ.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMenuSet();
    _loadMenuItems();
    final org = Get.find<OrganisationController>();
    ever(org.showMenuItemPrices, (_) => _applyFilters());
  }

  Future<void> _loadMenuSet() async {
    try {
      isLoading.value = true;
      final doc = await FirebaseFirestore.instance
          .collection('menus')
          .doc(menuId)
          .get();

      if (doc.exists && doc.data() != null) {
        menuSet.value = MenuModel.fromFirestore(doc.data()!, doc.id);
      } else {
        menuSet.value = null;
      }
    } catch (e) {
      menuSet.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      isItemsLoading.value = true;

      final snap = await FirebaseFirestore.instance
          .collection('menu_items')
          .where('menuId', isEqualTo: menuId)
          .orderBy('category')
          .orderBy('createdAt', descending: false)
          .get();

      final list =
          snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();

      items.assignAll(list);
      _applyFilters();
    } catch (e) {
      items.clear();
      filteredItems.clear();
    } finally {
      isItemsLoading.value = false;
    }
  }

  // ---------- FILTER & SORT HELPERS ----------

  void setSearchQuery(String value) {
    searchQuery.value = value;
    _applyFilters();
  }

  void setCategoryFilter(String? category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void setMinPrice(String value) {
    if (value.trim().isEmpty) {
      minPrice.value = null;
    } else {
      minPrice.value = double.tryParse(value.trim());
    }
    _applyFilters();
  }

  void setMaxPrice(String value) {
    if (value.trim().isEmpty) {
      maxPrice.value = null;
    } else {
      maxPrice.value = double.tryParse(value.trim());
    }
    _applyFilters();
  }

  void setSortType(MenuItemsSortType type) {
    sortType.value = type;
    _applyFilters();
  }

  void _applyFilters() {
    var list = [...items];

    final org = Get.find<OrganisationController>();
    final showPrices = org.showMenuItemPrices.value;

    // ✅ If prices are hidden, disable price filters & price sorts
    if (!showPrices) {
      // Optional: clear these so your UI state stays consistent
      minPrice.value = null;
      maxPrice.value = null;

      // If currently set to a price sort, force to Name A-Z
      if (sortType.value == MenuItemsSortType.priceLowHigh ||
          sortType.value == MenuItemsSortType.priceHighLow) {
        sortType.value = MenuItemsSortType.nameAZ;
      }
    }

    // -----------------------
    // SEARCH by name/desc
    // -----------------------
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((item) {
        final name = item.name.toLowerCase();
        final desc = (item.description ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }

    // -----------------------
    // CATEGORY filter
    // -----------------------
    final cat = selectedCategory.value;
    if (cat != null && cat.trim().isNotEmpty) {
      list = list.where((item) => item.category == cat).toList();
    }

    // -----------------------
    // PRICE filter (only if enabled)
    // -----------------------
    if (showPrices) {
      final minP = minPrice.value;
      final maxP = maxPrice.value;

      if (minP != null) {
        list = list.where((item) {
          final p = item.price;
          if (p == null) return false;
          return p >= minP;
        }).toList();
      }

      if (maxP != null) {
        list = list.where((item) {
          final p = item.price;
          if (p == null) return false;
          return p <= maxP;
        }).toList();
      }
    }

    // -----------------------
    // SORT
    // -----------------------
    switch (sortType.value) {
      case MenuItemsSortType.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;

      case MenuItemsSortType.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
        break;

      case MenuItemsSortType.priceLowHigh:
        if (showPrices) {
          list.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        } else {
          // fallback safety
          list.sort((a, b) => a.name.compareTo(b.name));
        }
        break;

      case MenuItemsSortType.priceHighLow:
        if (showPrices) {
          list.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        } else {
          // fallback safety
          list.sort((a, b) => a.name.compareTo(b.name));
        }
        break;

      case MenuItemsSortType.dateNewest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;

      case MenuItemsSortType.dateOldest:
        list.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
    }

    filteredItems.assignAll(list);
  }

  // ---------- CRUD ----------

  Future<void> createItem({
    required String name,
    required String category, // String-based category
    required FoodType foodType,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? allergens, // ✅ NEW (optional)
  }) async {
    try {
      final ref = FirebaseFirestore.instance.collection('menu_items').doc();

      // ✅ clean allergens (keep only allowed + unique + sorted)
      final cleanedAllergens = (allergens ?? [])
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty && MenuItem.allowedAllergens.contains(e))
          .toSet()
          .toList()
        ..sort();

      final item = MenuItem(
        menuItemId: ref.id,
        menuId: menuId,
        organisationId: menuSet.value?.organisationId,
        name: name,
        category: category,
        description: description,
        price: price,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        foodType: foodType,
        allergens: cleanedAllergens.isEmpty ? null : cleanedAllergens, // ✅ NEW
      );

      await ref.set(item.toFirestoreCreate());

      items.add(item);
      _applyFilters();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem(MenuItem item) async {
    if (item.menuItemId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(item.menuItemId)
          .update(item.toFirestoreUpdate());

      final index = items.indexWhere((i) => i.menuItemId == item.menuItemId);
      if (index != -1) {
        items[index] = item;
        items.refresh();
      }
      _applyFilters();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(MenuItem item) async {
    if (item.menuItemId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(item.menuItemId)
          .delete();

      items.removeWhere((i) => i.menuItemId == item.menuItemId);
      _applyFilters();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      rethrow;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM d, yyyy • hh:mm a').format(date);
  }
}
