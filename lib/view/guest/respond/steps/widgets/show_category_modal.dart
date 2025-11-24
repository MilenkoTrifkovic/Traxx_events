import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_margines.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

// Show modal with dishes for a specific category
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
                        category.toString().split('.').last.capitalizeString(),
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
                        padding: AppPadding.all(context, paddingType: Sizes.sm),
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
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
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
