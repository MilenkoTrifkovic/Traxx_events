import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/set_menus_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class SelectableCategoryChooser extends StatelessWidget {
  final List<MenuCategory> categories;
  final SetMenusController setMenusController;
  const SelectableCategoryChooser(
      {super.key, required this.categories, required this.setMenusController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText.styledBodyMedium(
            context, 'Selected category allows guest to choose their meal',
            weight: FontWeight.bold),
        AppSpacing.verticalXs(context),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: categories.map((category) {
                    if (!setMenusController.checkIfSelectAllowed(category)) {
                      return SizedBox.shrink();
                    }

                    return Padding(
                      padding:
                          AppPadding.horizontal(context, paddingType: Sizes.sm),
                      child: FilterChip(
                        label: AppText.styledBodySmall(
                          context,
                          category.name,
                          color: setMenusController.selectableCategories
                                  .contains(category)
                              ? AppColors.primary(context)
                              : null,
                        ),
                        selected: setMenusController.selectableCategories
                            .contains(category),
                        onSelected: (selected) {
                          print(
                              'Category ${category.name} selected: $selected');
                          if (selected) {
                            setMenusController.addRemoveSelectableCategory(
                                category, true);
                          } else {
                            setMenusController.addRemoveSelectableCategory(
                                category, false);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ))
      ],
    );
  }
}
