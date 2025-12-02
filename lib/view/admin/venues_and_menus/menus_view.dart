import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/menus_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/menu_card.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_card.dart';

/// A screen that displays the venue management interface.
///
/// This screen includes:
/// - Venue list display
class MenusView extends StatefulWidget {
  const MenusView({super.key});

  @override
  State<MenusView> createState() => _MenusViewState();
}

class _MenusViewState extends State<MenusView> {
  late MenusScreenController controller;

  @override
  void initState() {
    super.initState();
    // controller = Get.put(MenusScreenController());
  }

  // Access the global MenusController
  final menusController = Get.find<MenusController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: menusController.filteredMenuItems.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildVenuesListSection(context, menusController),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the venue creation form

  /// Builds the horizontal list of venue cards
  Widget _buildVenuesListSection(
      BuildContext context, MenusController menusController) {
    return Obx(() {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: menusController.filteredMenuItems.length,
        itemBuilder: (context, index) {
          final menuItem = menusController.filteredMenuItems[index];
          return Padding(
            padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
            // child: Text(menuItem.name),
            child: MenuCard(
              menu: menuItem,
              onDelete: () {
                // Call the delete method from the controller
                menusController.removeMenuItem(menuItem.menuItemId!);
              },
              onTap: () {

              },
            ),
          );
        },
      );
    });
  }
}
