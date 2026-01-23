import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_margines.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/category_field.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

class GuestMenuForm extends StatelessWidget {
  final Event event;
  final RespondController respondController;
  final int responseId;

  const GuestMenuForm(
      {super.key,
      required this.responseId,
      required this.respondController,
      required this.event});

  void showCategoryModal(
      BuildContext context,
      MenuCategory category,
      List<MenuItemOld> dishes,
      GuestResponse guestResponse,
      Function(MenuItemOld)? onDishSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, //allow full height
      backgroundColor: Colors.transparent, //allow rounded corners
      builder: (BuildContext context) {
        return Container(
          decoration: AppDecorations.bottomModal(context),
          child: Column(
            children: [
              Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 1, child: Container()),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: AppText.styledBodyLarge(
                          context,
                          category
                              .toString()
                              .split('.')
                              .last
                              .capitalizeString(),
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => popRoute(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SectionDivider(),
              Expanded(
                child: ListView.builder(
                  padding: AppPadding.all(context, paddingType: Sizes.sm),
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    final dishIngredients =
                        dish.ingredientsAllergens.split(',').map((e) {
                      return e.trim().capitalizeString();
                    }).join(', ');
                    return Card(
                      margin: AppMargins.all(context, marginType: Sizes.sm),
                      child: InkWell(
                        onTap: () {
                          onDishSelected?.call(dish);
                          popRoute(context);
                        },
                        child: Padding(
                          padding:
                              AppPadding.all(context, paddingType: Sizes.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dish.imageUrl != null &&
                                  dish.imageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: AppBorderRadius.radius(context,
                                      size: Sizes.sm),
                                  child: Image.network(
                                    dish.imageUrl!,
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              AppSpacing.verticalMd(context),
                              AppText.styledBodyLarge(
                                context,
                                dish.dishName.capitalizeString(),
                                weight: FontWeight.bold,
                              ),
                              if (dish.description.isNotEmpty) ...[
                                AppSpacing.verticalXs(context),
                                AppText.styledBodyMedium(
                                  context,
                                  dish.description.capitalizeString(),
                                ),
                              ],
                              if (dish.ingredientsAllergens.isNotEmpty) ...[
                                AppSpacing.verticalXs(context),
                                AppText.styledBodySmall(
                                  context,
                                  'Ingredients: $dishIngredients',
                                  color: AppColors.error(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                    serviceType: event.serviceType,
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

double calculateItemWidth(
    BuildContext context, int itemCount, double maxWidth) {
  maxWidth = maxWidth - ((itemCount - 1) * 4);
  final isPhone = ScreenSize.isPhone(context);
  final maxColumns = isPhone ? 3 : 4;
  int columns;
  if (itemCount <= 2) {
    return (maxWidth / itemCount);
  }
  if (itemCount <= maxColumns) {
    columns = itemCount;
  } else {
    if (itemCount % maxColumns == 0) {
      columns = maxColumns;
    } else if (itemCount % 2 == 0) {
      columns = 2;
    } else if (itemCount % 3 == 0) {
      columns = 3;
    } else {
      columns = maxColumns;
    }
  }
  return (maxWidth / columns);
}
