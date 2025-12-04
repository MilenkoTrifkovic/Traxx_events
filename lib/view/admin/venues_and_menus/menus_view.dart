import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/menus_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_menu_popup_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/menu_card.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/menu_details_dialog.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/sort_menus.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';

/// A screen that displays the menu management interface.
///
class MenusView extends StatefulWidget {
  const MenusView({super.key});

  @override
  State<MenusView> createState() => _MenusViewState();
}

class _MenusViewState extends State<MenusView> {
  late MenusScreenController controller;
  late final SnackbarMessageController snackbarMessageController;

  @override
  void initState() {
    super.initState();
    snackbarMessageController = Get.find<SnackbarMessageController>();
    controller = Get.put(MenusScreenController());
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
      if (menusController.filteredMenuItems.isEmpty &&
          menusController.menuItems.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height -
              200, // Give it most of the screen height
          child: EmptyState(
            title: 'No Menus Found',
            imageAsset: Constants.emptyMenu,
            description: 'Create your first menu by tapping the button below.',
            buttonText: 'Add First Menu',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CreateMenuPopupView(
                    controller: controller,

                    // venuesController: venuesController,
                  );
                },
              ).then(
                (value) async {
                  if (value != null && value is bool && value) {
                    try {
                      showLoadingIndicator();
                      final createdMenu = await controller.submitForm();
                      // venuesController.addVenue(createdVenue);//////////////////
                      menusController.addMenuItem(createdMenu);
                      snackbarMessageController
                          .showSuccessMessage('Menu created successfully.');
                    } on Exception catch (e) {
                      snackbarMessageController
                          .showErrorMessage('Error creating menu');
                    } finally {
                      hideLoadingIndicator();
                    }
                  } else {}
                },
              );
            },
          ),
        );
      }

      return Padding(
        padding: AppPadding.all(context, paddingType: Sizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SortMenus(),
            AppSpacing.verticalXxxs(context),
            ListView.builder(
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
                      showDialog(context: context, builder: (context) {
                        return MenuDetailsDialog(menu: menuItem);
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
