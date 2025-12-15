import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/menu_card_sections/first_section_menus.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/menu_card_sections/fourth_section_venues.dart';

/// A card widget that displays event information in a consistent format.
///
/// Features:
/// - Displays event cover image with fallback placeholder
/// - Shows event name, date, and status
class MenuCard extends StatelessWidget {
  /// The event data to display in the card
  final MenuItem menu;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MenuCard({
    super.key,
    required this.menu,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.borderInput,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      height: 88,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: FirstSectionMenus(menu: menu)),
            // if (ScreenSize.isDesktop(context))
            //   Expanded(child: SecondSection(event: event)),
            // if (ScreenSize.isDesktop(context))
            //   Expanded(child: ThirdSection(event: event)),
            if (ScreenSize.isDesktop(context))
              Expanded(child: FourthSection(menu: menu, onPressed: onDelete)),
          ],
        ),
      ),
    );
    // return Card(
    //   clipBehavior: Clip.antiAlias,
    //   elevation: 2,
    //   child: InkWell(
    //     onTap: onTap,
    //     child: Padding(
    //       padding: AppPadding.all(context, paddingType: Sizes.sm),
    //       child: Row(
    //         children: [
    //           Expanded(child: FirstSection(event: event)),
    //           Expanded(child: SecondSection(event: event)),
    //           Expanded(child: ThirdSection(event: event)),
    //           Expanded(child: FourthSection(event: event)),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
