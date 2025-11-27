import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_item_row.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/search_dropdown.dart';

class MenuSelectionDialog extends StatelessWidget {
  final Map<MenuCategory, List<MenuItem>> availableMenus;
  final Map<MenuCategory, List<MenuItem>> selectedMenus;
  final void Function(List<MenuItem> selected) onSelectionChanged;
  final void Function(MenuItem selected) selectNewMenuItem;
  final void Function() updateEvent;

  const MenuSelectionDialog({
    super.key,
    required this.availableMenus,
    required this.selectedMenus,
    required this.onSelectionChanged,
    required this.selectNewMenuItem,
    required this.updateEvent,
  });

  @override
  Widget build(BuildContext context) {
    List<MenuItem> tempSelected = List<MenuItem>.from(selectedMenus.values);
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
                      Icon(availableMenus.keys.first.icon, size: 32),
                      AppSpacing.horizontalSm(context),
                      AppText.styledHeadingLarge(
                        context,
                        'Add ${availableMenus.keys.first.name.toString().capitalize}',
                        color: Colors.black,
                      ),
                    ],
                  ),
                  AppSpacing.verticalSm(context),
                  SearchableDropdownOverlay(
                    items: availableMenus.values
                        .expand((e) => e)
                        .toList(), // List<Menu> ili bilo šta
                    searchKey: (item) => item.name, // šta se pretražuje
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
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          onSelectionChanged(tempSelected);
                          updateEvent();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                  SelectedMenuItemRow(
                      menuItem: availableMenus.values.first.first),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
