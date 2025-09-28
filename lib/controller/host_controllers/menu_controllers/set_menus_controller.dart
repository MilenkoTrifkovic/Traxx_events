import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/mixins/selected_event_mixin.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:uuid/uuid.dart';

/// Controller that manages guest input fields for an event.
/// It fetches guest form configuration from Firestore via HostServices,
/// manages a list of custom guest fields, and validates/saves those fields.
class SetMenusController extends GetxController with SelectedEventMixin {
  // late final Event event;
  RxBool isLoading = true.obs;

  final ImageServices _imageServices = ImageServices();

  /// Reference to the HostController (used to get current event details).
  final StorageServices storageServices = Get.find<StorageServices>();
  // final AuthController authController = Get.find<AuthController>();
  final MenuControllersManager menuControllersManager =
      Get.find<MenuControllersManager>();

  /// Service that handles communication with the Firestore backend.
  final FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  //eventController that holds the selected event
  @override
  final EventController eventController = Get.find<EventController>();

  RxList<MenuItem> menus = <MenuItem>[].obs;
  RxSet<MenuCategory> selectableCategories = <MenuCategory>{}.obs;
  RxList<MenuCategory> menuCategories = <MenuCategory>[].obs;
  Map<String, XFile> menuImages = {};

  void _updateMenuCategories() {
    menuCategories.value =
        menus.map((element) => element.category).toSet().toList();
  }

  /// Constructor: initializes the document name and default fields.
  // SetMenusController(this.event) {//remove later
  SetMenusController() {
    // event = eventController.selectedEvent.value!;
  }

  /// If the Firestore database has saved menus, those are used.
  /// Otherwise, it creates one empty menu.
  Future<void> initializeMenus() async {
    print(
        'Selected event in controller: ${eventController.selectedEvent.value}');

    print('Initializing menus for event: ${selectedEvent.value}');
    String eventId = selectedEvent.value!.id!;
    menus.clear();
    menuImages.clear();

    // Initialize selectable categories from event
    selectableCategories.clear();
    selectableCategories.addAll(selectedEvent.value!.selectableCategories);

    try {
      final fetchedMenus = await firestoreServices.getMenus(eventId);
      if (fetchedMenus.isNotEmpty) {
        for (final menu in fetchedMenus) {
          if (menu.imagePath.isNotEmpty) {
            menu.imageUrl = await storageServices.loadImageURL(menu.imagePath);
          }
        }
        menus.value = fetchedMenus;
        _updateMenuCategories();
      } else {
        addMenuItem();
      }
    } catch (e) {
      // If fetch fails, fallback to default fields.
      print("Failed to load menus: $e");
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds a new empty menu item and returns its index.
  int addMenuItem() {
    MenuItem menuItem = MenuItem(
      id: Uuid().v4(),
    );
    menus.add(menuItem);
    menuControllersManager.getControllers(menuItem);
    _updateMenuCategories();
    return menus.length - 1;
  }

  MenuItem deleteMenuItem(int index) {
    final removedItem = menus.removeAt(index);
    menuControllersManager.disposeControllers(removedItem.id);
    _updateMenuCategories();
    return removedItem;
  }

  /// Updates the category of a specific menu item.
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the menu item to update
  /// - [menuCategory]: The new category to assign to the menu item
  ///
  /// This method:
  /// 1. Finds the menu item by its ID in the menus list
  /// 2. Creates a new copy of the item with updated category using copyWith
  /// 3. Updates the menus list with the modified item
  /// 4. Refreshes the list of unique menu categories
  void changeMenuCategory(String id, MenuCategory menuCategory) {
    int index = menus.indexWhere((item) => item.id == id);
    if (index != -1) {
      menus[index] = menus[index].copyWith(category: menuCategory);
      _updateMenuCategories();
    }
  }

  /// Saves all menu-related changes to Firestore.
  ///
  /// This method:
  /// - Synchronizes menu data with text controllers
  /// - Uploads any new menu images to storage
  /// - Saves menu information to Firestore
  /// - Persists selectable categories changes
  /// - Updates the selected event in eventController
  ///
  /// Returns true if all operations succeed, false if any operation fails.
  Future<bool> saveMenus() async {
    try {
      //removes selectableCategories if there are less than two menu items with that category
      //user cannot select from that category if there are not enough items
      selectableCategories
          .removeWhere((element) => !checkIfSelectAllowed(element));

      String eventId = selectedEvent.value!.id!;

      // First save all menu-related changes
      _syncroniseMenusAndControllers();
      for (var menu in menus) {
        if (menuImages.containsKey(menu.id)) {
          final imagePath =
              await storageServices.uploadImage(menuImages[menu.id]!);
          menu.imagePath = imagePath;
        }
      }
      await firestoreServices.saveMenusAndUpdateEventFields(eventId, menus, {
        'selectableMenuCategories':
            selectableCategories.map((e) => e.name).toList(),
      });
      //updates the selected event in eventController
      updateEvent((placeholder) => placeholder.copyWith(
          selectableCategories: selectableCategories.toList()));
      return true;
    } catch (e) {
      print('Error saving menus: $e');
      return false;
    }
  }

  //Adds text from controllers to menu items
  void _syncroniseMenusAndControllers() {
    for (MenuItem menu in menus) {
      final MenuItemControllers controllers =
          menuControllersManager.getControllers(menu);
      menu.updateFromControllers(controllers);
    }
  }

  /// Loads a menu image from the gallery.
  /// If an image was selected, it is stored in the menuImages map.
  /// Returns the selected image file or null if no image was selected.
  Future<XFile?> loadMenuImage({required MenuItem menuItem}) async {
    XFile? pickedImage = await _imageServices.pickImage(ImageSource.gallery);
    if (pickedImage != null) {
      // provjeriti radi li ovo dobro, cilj je samo jedna da se skladisti
      menuImages[menuItem.id] = pickedImage;
      return pickedImage;
    }
    return null;
  }

  /// Updates the list of selectable menu categories.
  /// If [add] is true, adds the [category] to selectable categories,
  /// otherwise removes it. Changes are persisted when saveMenus() is called.
  void addRemoveSelectableCategory(MenuCategory category, bool add) {
    if (add) {
      selectableCategories.add(category);
    } else {
      selectableCategories.remove(category);
    }
  }

  bool checkIfSelectAllowed(MenuCategory menuCategory) {
    int count = menus.where((e) => e.category == menuCategory).length;
    return count > 1;
  }
}
