import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller for editing menu selection responses
class GuestMenuSelectionEditController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;

  // Session controller
  final _guestSession = Get.find<GuestSessionController>();

  // 🆕 Guest ID for editing (can be main guest or companion)
  String? _editingGuestId;
  
  // Flag to prevent re-initialization
  bool _isInitialized = false;

  // 🆕 Current response - now gets from session using guestId
  MenuSelectionResponseModel? get menuSelectionResponse {
    final guestId = _editingGuestId ?? _guestSession.guest.value?.guestId;
    if (guestId == null) return null;
    return _guestSession.getMenuResponseForGuest(guestId);
  }

  // Available menu items
  final menuItems = <MenuItem>[].obs;

  // Selected menu item IDs
  final selectedMenuItemIds = <String>[].obs;

  /// 🆕 Initialize with optional guestId (for companion editing)
  void initialize({String? guestId}) {
    // Check if we're editing a different guest
    final isDifferentGuest = _editingGuestId != null && _editingGuestId != guestId;
    
    // Prevent re-initialization on widget rebuilds for the SAME guest
    if (_isInitialized && !isDifferentGuest) {
      print('⚠️ Controller already initialized for same guest, skipping...');
      return;
    }
    
    // If different guest, clear previous state
    if (isDifferentGuest) {
      print('🔄 Switching to different guest, clearing state...');
      _clearState();
    }
    
    _editingGuestId = guestId;
    _isInitialized = true;
    _loadMenuItems();
  }
  
  /// Clear all state when switching guests
  void _clearState() {
    menuItems.clear();
    selectedMenuItemIds.clear();
    isLoading.value = false;
    isSaving.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    // Will be called with guestId from navigation extra
  }

  /// Load menu items from Firestore
  Future<void> _loadMenuItems() async {
    try {
      isLoading.value = true;

      final event = _guestSession.event.value;
      if (event == null || event.selectedMenuItemIds == null) {
        print('⚠️ No menu items configured for this event');
        return;
      }

      print('📋 Loading ${event.selectedMenuItemIds!.length} menu items for event');

      // Fetch menu items
      final menuItemsSnapshot = await FirebaseFirestore.instance
          .collection('menu_items')
          .where(FieldPath.documentId, whereIn: event.selectedMenuItemIds)
          .where('isDisabled', isEqualTo: false)
          .get();

      menuItems.value = menuItemsSnapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();

      print('✅ Loaded ${menuItems.length} menu items');

      // Initialize selected IDs from current response
      if (menuSelectionResponse != null) {
        selectedMenuItemIds.value = List.from(menuSelectionResponse!.selectedMenuItemIds);
        print('📝 Initialized with ${selectedMenuItemIds.length} selected items');
      }

    } catch (e) {
      print('❌ Error loading menu items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle menu item selection
  void toggleMenuItem(String menuItemId) {
    if (selectedMenuItemIds.contains(menuItemId)) {
      selectedMenuItemIds.remove(menuItemId);
    } else {
      selectedMenuItemIds.add(menuItemId);
    }
    print('📝 Selected items: ${selectedMenuItemIds.length}');
  }

  /// Check if a menu item is selected
  bool isMenuItemSelected(String menuItemId) {
    return selectedMenuItemIds.contains(menuItemId);
  }

  /// Save menu selection responses
  Future<bool> saveResponses() async {
    try {
      isSaving.value = true;

      // Create updated response
      final updatedResponse = menuSelectionResponse!.copyWith(
        selectedMenuItemIds: selectedMenuItemIds,
      );

      // Update in session controller (which will save to Firestore)
      await _guestSession.updateMenuSelectionResponse(updatedResponse);

      print('✅ Menu selection responses saved successfully');
      return true;

    } catch (e) {
      print('❌ Error saving menu selection responses: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Cancel editing and go back
  void cancel(BuildContext context) {
    context.pop();
  }

  /// Get menu items grouped by category
  Map<String, List<MenuItem>> get menuItemsByCategory {
    final grouped = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      final category = item.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }
    return grouped;
  }

  /// Get list of categories
  List<String> get categories {
    return menuItemsByCategory.keys.toList()..sort();
  }
  
  @override
  void onClose() {
    // Clear state when controller is disposed
    _clearState();
    _isInitialized = false;
    _editingGuestId = null;
    super.onClose();
  }
}
