import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/menu_category_controller.dart';
import 'package:traxx_wepapp/controller/menus_list_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/add_menu_category_popup.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_menu_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

class MenusManagementHeader extends StatelessWidget {
  MenusManagementHeader({super.key});

  // use existing controllers registered with Get
  final MenusScreenController createController =
      Get.find<MenusScreenController>();
  final MenusListController listController = Get.find<MenusListController>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();
  
  // create controller for category management
  final MenuCategoryController categoryController =
      Get.put(MenuCategoryController());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Menus'),
        Row(
          children: [
            if (ScreenSize.isDesktop(context) == true)
              AppSearchInputField(
                hintText: 'Search menus...',
                onChanged: (value) {
                  // this will trigger _applyFilters() in controller
                  listController.searchQuery.value = value;
                },
              ),
            AppSpacing.horizontalXs(context),
            AppSecondaryButton(
              icon: Icons.category_outlined,
              text: 'Menu Categories',
              onPressed: () {
                // Clear form before opening dialog to ensure fresh state
                categoryController.clearForm();
                
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return AddMenuCategoryPopup(
                      controller: categoryController,
                    );
                  },
                ).then((categoryName) async {
                  // Clear form after dialog closes as well (for safety)
                  categoryController.clearForm();
                  
                  if (categoryName != null && categoryName is String) {
                    // Category already saved by controller
                    // Success message already shown
                  }
                });
              },
            ),
            AppSpacing.horizontalXs(context),
            AppPrimaryButton(
              icon: Icons.add,
              text: 'Add Menu',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CreateMenuPopupView(
                      controller: createController,
                    );
                  },
                ).then((value) async {
                  if (value != null && value is bool && value) {
                    try {
                      showLoadingIndicator();
                      // submitForm now returns MenuModel
                      final MenuModel createdMenuSet =
                          await createController.submitForm();

                      // update list UI (expects MenuModel)
                      listController.addMenuSet(createdMenuSet);

                      snackbarMessageController
                          .showSuccessMessage('Menu created successfully.');
                    } on Exception {
                      snackbarMessageController
                          .showErrorMessage('Error creating menu');
                    } finally {
                      hideLoadingIndicator();
                    }
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
