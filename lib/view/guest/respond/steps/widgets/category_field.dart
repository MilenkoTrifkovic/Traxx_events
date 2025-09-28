import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/extensions/string_extensions.dart';

/// A widget that displays a selectable menu category field with the currently selected dish.
///
/// This widget is wrapped in [Obx] to reactively update when menu selections change.
/// The field shows either a placeholder or the selected dish name based on the response state.
///
/// Note: The dish lookup is done directly in the widget - consider moving this logic
/// to the controller for better separation of concerns.
class CategoryField extends StatelessWidget {
  const CategoryField({
    super.key,
    required this.showCategoryModal,
    required this.itemWidth,
    required this.respondController,
    required this.responseId,
    required this.category,
    required this.dishes,
    required this.serviceType,
    required this.borderColor,
  });

  /// Color used for the container border
  final Color borderColor;

  /// Type of service (e.g., buffet, plated)
  final ServiceType serviceType;

  /// Callback to show the menu selection modal
  final Function() showCategoryModal;

  /// Width of the category field container
  final double itemWidth;

  /// Controller managing the response state
  final RespondController respondController;

  /// Index of the current response in allResponses list
  final int responseId;

  /// The menu category this field represents
  final MenuCategory category;

  /// List of available dishes for this category
  final List<MenuItem> dishes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: showCategoryModal,
      child: Container(
          width: itemWidth,
          height: 100,
          decoration: BoxDecoration(border: Border.all(color: borderColor)),
          child: Obx(() {
            //reactive to menu changes
            var id =
                respondController.allResponses[responseId].menus[category.name];
            return Column(
              children: [
                Expanded(
                  flex: 1,
                  child: AppText.styledBodyMedium(
                      weight: FontWeight.bold,
                      context,
                      category.name.capitalizeString()),
                ),
                Expanded(
                  flex: 4,
                  child: id == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: AppText.styledBodyLarge(
                                  weight: FontWeight.bold,
                                  context,
                                  overflow: TextOverflow.ellipsis,
                                  respondController
                                      .categoryFieldPlaceholder(category)),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: AppText.styledBodyLarge(
                                  overflow: TextOverflow.ellipsis,
                                  weight: FontWeight.bold,
                                  context,
                                  dishes //move to controller
                                      .firstWhere(
                                        (element) =>
                                            element.id ==
                                            respondController
                                                .allResponses[responseId]
                                                .menus[category.name],
                                      )
                                      .dishName,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                Expanded(flex: 1, child: Container())
              ],
            );
          })),
    );
  }
}
