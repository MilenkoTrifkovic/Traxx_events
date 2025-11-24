import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/category_field.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/layout_utils.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/show_category_modal.dart';

class GuestMenuForm extends StatelessWidget {
  final Event event;
  final RespondController respondController;
  final int responseId;

  const GuestMenuForm(
      {super.key,
      required this.responseId,
      required this.respondController,
      required this.event});

  //Calculate item width based on screen size and number of items

  @override
  Widget build(BuildContext context) {
    final guestResponse = respondController.allResponses[responseId];
    final menusByCategory = respondController.getMenusByCategory();
    final activeCategories = respondController.getActiveCategories();
    final String menusSectionTitle = event.serviceType == ServiceType.plated
        ? 'Select Your Menu'
        : 'Event Menu';

    if (activeCategories.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        AppSpacing.verticalMd(context),
        // Header with icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: AppColors.primaryOld(context),
            ),
            AppSpacing.horizontalSm(context),
            Flexible(
              child: AppText.styledBodyMedium(
                textAlign: TextAlign.center,
                context,
                menusSectionTitle,
                weight: FontWeight.bold,
              ),
            ),
            AppSpacing.horizontalSm(context),
            Icon(
              Icons.restaurant_menu,
              color: AppColors.primaryOld(context),
            )
          ],
        ),
        AppSpacing.verticalXs(context),
        // Menu items
        LayoutBuilder(builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          double itemWidth =
              calculateItemWidth(context, activeCategories.length, maxWidth);
          return Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: [
              ...activeCategories.map((category) {
                final List<MenuItemOld> dishes =
                    menusByCategory[category] ?? [];

                return Obx(() {
                  bool hasError = respondController.shouldShowCategoryError(
                    category,
                    responseId,
                    event.selectableCategories.contains(category),
                  );
                  return CategoryField(
                    borderColor: hasError
                        ? AppColors.error(context)
                        : AppColors.onBackground(context),
                    serviceType: event.serviceType!,
                    showCategoryModal: () => showCategoryModal(
                      context,
                      category,
                      dishes,
                      guestResponse,
                      event.serviceType == ServiceType.plated
                          ? (event.selectableCategories.contains(category)
                              ? (dish) => respondController.setSelectedDish(
                                  dish, responseId)
                              : null)
                          : null,
                    ),
                    itemWidth: itemWidth,
                    respondController: respondController,
                    responseId: responseId,
                    category: category,
                    dishes: dishes,
                  );
                });
              })
            ],
          );
        }),
      ],
    );
  }
}
