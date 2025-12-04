import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class MenusController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();
  final StorageServices _storageServices = Get.find<StorageServices>();
  // Use global snackbar message controller
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  // Observable list of menu items (for currently selected organisation)
  final menuItems = <MenuItem>[].obs;
  final filteredMenuItems = <MenuItem>[].obs;
  // We only support a single organisation in this controller, so keep a single list
  // and avoid a per-organisation cache map.

  @override
  void onInit() {
    super.onInit();
    // Optionally load current organisation menu items on init
    _loadMenuItems();
  }

  /// Returns cached menu items for an organisation if available, otherwise fetches from Firestore, caches, and returns them.
  Future<List<MenuItem>> getMenuItemsByOrganisationId(
      String organisationId) async {
    // If we've already loaded menu items for the (single) organisation, return them.
    if (menuItems.isNotEmpty) return menuItems;

    final menuList = await _firestoreServices.getAllMenus(organisationId);
    final updated = await _withImageUrls(menuList);
    // Cache into the single observable list used throughout the app
    menuItems.assignAll(updated);
    return updated;
  }
  void sortMenus(SortType sortType) {
    switch (sortType) {
      case SortType.nameAZ:
        filteredMenuItems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZA:
        filteredMenuItems.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortType.dateNewest:
        // TODO: Handle this case.
        break;
      case SortType.dateOldest:
        // TODO: Handle this case.
        break;
    }
  }

  Future<List<MenuItem>> _withImageUrls(List<MenuItem> menuList) async {
    return Future.wait(menuList.map((item) async {
      if (item.imageUrl != null || item.imagePath == null) return item;
      final url = await _storageServices.loadImageURL(item.imagePath);
      if (url == null) return item;
      return item.copyWith(imageUrl: url);
    }));
  }

  void filterMenus(String value) {
    if (value.isEmpty) {
      filteredMenuItems.assignAll(menuItems);
    } else {
      filteredMenuItems.assignAll(menuItems.where(
          (event) => event.name.toLowerCase().contains(value.toLowerCase())));
      print('Filtered menu items count: ${filteredMenuItems.length}');
    }
  }

  /// Loads all menu items for the current organisation and updates the observable list
  Future<void> _loadMenuItems() async {
    try {
      final organisationId = _authController.organisationId!;
      final allMenuItems = await _firestoreServices.getAllMenus(organisationId);
      menuItems.assignAll(await _withImageUrls(allMenuItems));
      filteredMenuItems.assignAll(menuItems);
    } catch (e) {
      print('Error loading menu items: $e');
    }
  }

  MenuItem? getMenuItemById(String menuItemId) {
    try {
      return menuItems.firstWhere((m) => m.menuItemId == menuItemId);
    } catch (e) {
      print('Menu item with ID $menuItemId not found: $e');
      return null;
    }
  }

  /// Adds a new menu item locally (does not persist to Firestore)
  void addMenuItem(MenuItem item) {
    menuItems.add(item);
    filteredMenuItems.assignAll(menuItems);
  }

  /// Creates a new menu item in Firestore and optionally adds it to local list
  // Future<MenuItem?> createMenuItem(MenuItem item,
  //     {bool addToLocal = true}) async {
  //   try {
  //     final created = await _firestoreServices.createMenuItem(item);
  //     if (addToLocal) menuItems.add(created);
  //     return created;
  //   } catch (e) {
  //     print('Failed to create menu item: $e');
  //     snackbarMessageController
  //         .showErrorMessage('Failed to create menu item: $e');
  //     return null;
  //   }
  // }

  /// Updates an existing menu item in Firestore and local cache
  // Future<bool> updateMenuItem(MenuItem item) async {
  //   if (item.menuItemId == null) return false;
  //   try {
  //     await _firestoreServices.updateMenuItem(item);
  //     final idx = menuItems.indexWhere((m) => m.menuItemId == item.menuItemId);
  //     if (idx != -1) menuItems[idx] = item;
  //     return true;
  //   } catch (e) {
  //     print('Failed to update menu item: $e');
  //     snackbarMessageController
  //         .showErrorMessage('Failed to update menu item: $e');
  //     return false;
  //   }
  // }

  // / Deletes a menu item from Firestore and updates local cache
  Future<bool> removeMenuItem(String menuItemId) async {
    try {
      showLoadingIndicator();
      await _firestoreServices.deleteMenuItem(menuItemId);
      menuItems.removeWhere((m) => m.menuItemId == menuItemId);
      // Ensure our primary cache is updated
      menuItems.removeWhere((m) => m.menuItemId == menuItemId);
      filteredMenuItems.removeWhere((m) => m.menuItemId == menuItemId);
      snackbarMessageController
          .showSuccessMessage('Menu item deleted successfully!');
      return true;
    } catch (e) {
      print('Failed to remove menu item $menuItemId: $e');
      snackbarMessageController
          .showErrorMessage('Failed to delete menu item: $e');
      return false;
    } finally {
      hideLoadingIndicator();
    }
  }
}
