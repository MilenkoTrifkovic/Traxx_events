import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/menu_controllers/set_menus_controller.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_margines.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/menu_section/widgets/upload_photo.dart';

// Widget _buildItem(
//     Animation<double> animation,
//     MenuItem item,
//   ) {
class MenuForm extends StatelessWidget {
  final MenuItemOld item;
  final Animation<double> animation;
  final void Function(int index) onPressed;
  final int index;

  MenuForm(
      {super.key,
      required this.item,
      required this.animation,
      required this.onPressed,
      required this.index});

  final SetMenusController setMenusController = Get.find<SetMenusController>();
  String? fieldValidation(String message, String? value) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
          .animate(CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      )),
      child: Container(
        margin: AppMargins.top(context, marginType: Sizes.sm),
        decoration: AppDecorations.formContainer(context),
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.sm),
          child: Column(
            children: [
              AppText.styledBodyMedium(context, "Menu Item ${index + 1}",
                  weight: FontWeight.bold),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 1, // Square aspect ratio
                      child: UploadMenuPhoto(
                        menuItem: item,
                        size: double.infinity, // Let parent control size
                      ),
                    ),
                    AppSpacing.horizontalXs(context),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: setMenusController
                                .menuControllersManager
                                .getControllers(item)
                                .dishName,
                            decoration: InputDecoration(labelText: 'Dish Name'),
                            validator: (value) => fieldValidation(
                                'Please enter a dish name', value),
                          ),
                          AppSpacing.verticalXs(context),
                          TextFormField(
                            controller: setMenusController
                                .menuControllersManager
                                .getControllers(item)
                                .description,
                            decoration:
                                InputDecoration(labelText: 'Description'),
                            // validator: (value) => fieldValidation(
                            //     'Please enter a description', value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalXs(context),
              TextFormField(
                controller: setMenusController.menuControllersManager
                    .getControllers(item)
                    .ingredientsAllergens,
                decoration: InputDecoration(labelText: 'Ingredients/Allergens'),
                validator: (value) => fieldValidation(
                    'Please enter ingredients/allergens', value),
              ),
              AppSpacing.verticalXs(context),
              DropdownButtonFormField<MenuCategory>(
                initialValue: MenuCategory.values.firstWhere(
                    (e) => e == item.category,
                    orElse: () => MenuCategory.other),
                onChanged: (value) {
                  setMenusController.changeMenuCategory(
                      item.menuItemId, value!);
                },
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: MenuCategory.values.map((category) {
                  // Convert enum value to display text (e.g., mainCourse -> Main Course)
                  String displayText = category
                      .toString()
                      .split('.')
                      .last
                      .split(RegExp(r'(?=[A-Z])'))
                      .map((word) => word[0].toUpperCase() + word.substring(1))
                      .join(' ');

                  return DropdownMenuItem(
                    value: category,
                    child: AppText.styledBodyMedium(context, displayText),
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.error(context)),
                onPressed: () =>
                    onPressed(setMenusController.menus.indexOf(item)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
