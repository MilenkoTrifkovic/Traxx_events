import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class MenuPanelController {
  final AdminEventDetailsController adminEventDetailsController;

  MenuPanelController(this.adminEventDetailsController);
  Rx<Map<MenuCategory, List<MenuItem>>> availableMenus =
      Rx<Map<MenuCategory, List<MenuItem>>>({});

  void populateAvailableMenus() {
    final items = adminEventDetailsController.availableMenuItems;
    final Map<MenuCategory, List<MenuItem>> grouped = {};
    for (final item in items) {
      final category = item.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }
    availableMenus.value = grouped;
  }
  // Add any menu panel-specific logic here
}
