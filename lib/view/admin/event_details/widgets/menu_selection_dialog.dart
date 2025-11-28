import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get/state_manager.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_item_row.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/search_dropdown.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

class MenuSelectionDialog extends StatelessWidget {
  // final Map<MenuCategory, List<MenuItem>> availableMenus;
  // final Map<MenuCategory, List<MenuItem>> selectedMenus;
  final Rx<List<MenuItem>> selectedMenus;
  final Rx<List<MenuItem>> availableMenus1;
  final void Function(List<MenuItem> selected) onSelectionChanged;
  final void Function(MenuItem selected) selectNewMenuItem;
  final Future<void> Function() updateEvent;
  final MenuCategory category;
  final void Function(MenuItem item)? onRemoveMenuItem;

  const MenuSelectionDialog({
    super.key,
    // required this.availableMenus,
    required this.selectedMenus,
    required this.onSelectionChanged,
    required this.selectNewMenuItem,
    required this.updateEvent,
    required this.category,
    required this.onRemoveMenuItem,
    required this.availableMenus1,
  });

  @override
  Widget build(BuildContext context) {
    // List<MenuItem> tempSelected = List<MenuItem>.from(selectedMenus.values);
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: StatefulBuilder(
        builder: (context, setState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 488,
            ),
            child: Padding(
              padding: AppPadding.all(context, paddingType: Sizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(category.icon, size: 32),
                      AppSpacing.horizontalSm(context),
                      AppText.styledHeadingLarge(
                        context,
                        'Add ${category.name.toString().capitalize}',
                        color: Colors.black,
                      ),
                    ],
                  ),
                  // AppSpacing.verticalSm(context),
                  Obx(() {
                    final menus = availableMenus1.value
                        .where((item) => item.category == category)
                        .toList();
                    return SearchableDropdownOverlay(
                      // items: availableMenus.values.expand((e) => e).toList(),
                      items: menus.toList(),
                      searchKey: (item) => item.name,
                      itemBuilder: (item) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl ?? '',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(Icons.broken_image, size: 40),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;

                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image,
                                          size: 20, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            AppText.styledBodyMedium(context, item.name,
                                weight: AppFontWeight.semiBold),
                          ],
                        ),
                      ),
                      onItemTap: (item) {
                        selectNewMenuItem(item);
                        print("Selected: ${item.name}");
                      },
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                          onPressed: () {},
                          child: AppText.styledMetaSmall(
                              context, 'Create new menu',
                              color: AppColors.primaryAccent)),
                    ],
                  ),
                  AppSpacing.verticalSm(context),
                  AppText.styledHeadingMedium(
                      context, 'Options for guests to choose from: ',
                      color: Colors.black),
                  AppSpacing.verticalSm(context),
                  Expanded(
                    // height: 500,
                    child: Obx(() {
                      final itemsForThisCategory = selectedMenus.value
                          .where((item) => item.category == category)
                          .toList();
                      return ListView.builder(
                        itemCount: itemsForThisCategory.length,
                        itemBuilder: (context, index) {
                          final item = itemsForThisCategory[index];
                          return Padding(
                            padding: AppPadding.bottom(context,
                                paddingType: Sizes.xxs),
                            child: SelectedMenuItemRow(
                              menuItem: item,
                              onRemove: onRemoveMenuItem != null
                                  ? () => onRemoveMenuItem!(item)
                                  : null,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  AppSpacing.verticalSm(context),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expanded(child: SizedBox()),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppSecondaryButton(
                              text: 'Cancel',
                              onPressed: () {
                                popRoute(context, false);
                              }),
                          AppSpacing.horizontalXs(context),
                          AppPrimaryButton(
                            text: 'Save Choices',
                            onPressed: () async {
                              popRoute(context, true);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
