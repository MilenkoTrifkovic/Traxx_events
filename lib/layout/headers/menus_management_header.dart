import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/menu_category_controller.dart';
import 'package:traxx_wepapp/controller/menus_list_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/add_menu_category_popup.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_menu_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';
import 'package:google_fonts/google_fonts.dart';

class MenusManagementHeader extends StatelessWidget {
  MenusManagementHeader({super.key});

  final MenusScreenController createController =
      Get.find<MenusScreenController>();
  final MenusListController listController = Get.find<MenusListController>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  final MenuCategoryController categoryController =
      Get.put(MenuCategoryController());

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = ScreenSize.isDesktop(context);
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ White Poppins heading
        Text(
          'Menus',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),

        Row(
          children: [
            if (isDesktop) ...[
              AppSearchInputField(
                hintText: 'Search menus...',
                onChanged: (value) {
                  listController.searchQuery.value = value;
                },
              ),
              AppSpacing.horizontalXs(context),
            ],

            // ✅ Menu Categories — SAME style as "Preview Guest Page"
            AppPrimaryButton(
              text: isDesktop ? 'Menu Categories' : '',
              icon: Icons.category_outlined,
              height: 44,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(1),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              onPressed: () {
                categoryController.clearForm();

                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => AddMenuCategoryPopup(
                    controller: categoryController,
                  ),
                ).then((_) {
                  categoryController.clearForm();
                });
              },
            ),

            AppSpacing.horizontalXs(context),

            // ✅ Add Menu (keep your primary style)
            AppPrimaryButton(
              icon: Icons.add,
              text: isDesktop ? 'Add Menu' : '',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CreateMenuPopupView(
                    controller: createController,
                  ),
                ).then((value) async {
                  if (value == true) {
                    try {
                      showLoadingIndicator();
                      final MenuModel createdMenuSet =
                          await createController.submitForm();
                      listController.addMenuSet(createdMenuSet);

                      snackbarMessageController
                          .showSuccessMessage('Menu created successfully.');
                    } catch (_) {
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
