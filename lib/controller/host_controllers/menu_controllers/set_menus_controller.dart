import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:uuid/uuid.dart';

/// Controller that manages guest input fields for an event.
/// It fetches guest form configuration from Firestore via HostServices,
/// manages a list of custom guest fields, and validates/saves those fields.
class SetMenusController {
  RxBool isLoading = true.obs;

  final ImageServices _imageServices = ImageServices();

  /// Reference to the HostController (used to get current event details).
  final HostController hostController = Get.find<HostController>();
  final StorageServices storageServices = Get.find<StorageServices>();
  // final AuthController authController = Get.find<AuthController>();
  final MenuControllersManager menuControllersManager =
      Get.find<MenuControllersManager>();

  /// Service that handles communication with the Firestore backend.
  late final FirestoreServices firestoreServices;

  List<MenuItem> menus = [];
  Map<String, XFile> menuImages = {};

  /// Constructor: initializes the document name and default fields.
  SetMenusController() {
    firestoreServices = Get.find<FirestoreServices>();
  }

  /// If the Firestore database has saved menus, those are used.
  /// Otherwise, it creates one empty menu.
  Future<void> initializeMenus() async {
    String eventId = hostController.selectedEvent.value!.id!;
    menus.clear();
    menuImages.clear();

    try {
      final fetchedMenus = await firestoreServices.getMenus(eventId);
      if (fetchedMenus.isNotEmpty) {
        for (final menu in fetchedMenus) {
          if (menu.imagePath.isNotEmpty) {
            menu.imageUrl = await storageServices.loadImageURL(menu.imagePath);
          }
        }
        menus = fetchedMenus;
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
    return menus.length - 1;
  }

  MenuItem deleteMenuItem(int index) {
    final removedItem = menus.removeAt(index);
    menuControllersManager.disposeControllers(removedItem.id);
    return removedItem;
  }

  void changeMenuCategory(String id, MenuCategory menuCategory) {
    int index = menus.indexWhere((item) => item.id == id);
    if (index != -1) {
      menus[index] = menus[index].copyWith(category: menuCategory);
    }
  }

  Future<bool> saveMenus() async {
    try {
      String eventId = hostController.selectedEvent.value!.id!;
      syncroniseMenusAndControllers();
      for (var menu in menus) {
        if (menuImages.containsKey(menu.id)) {
          final imagePath =
              await storageServices.uploadImage(menuImages[menu.id]!);
          menu.imagePath = imagePath;
        }
      }
      await firestoreServices.saveMenus(menus, eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  //Adds text from controllers to menu items
  void syncroniseMenusAndControllers() {
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
}
