import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class MenusManagementHeader extends StatelessWidget {
  MenusManagementHeader.VenuesManagementHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Venues & Menus'),
        Row(
          children: [
            // if (ScreenSize.isDesktop(context) == true)
            //   AppSearchInputField(
            //     hintText: 'Search events...',
            //     onChanged: (value) {
            //       eventListController.filterEvents(value);
            //     },
            //   ),
            // AppSpacing.horizontalXs(context),
            AppPrimaryButton(
                icon: Icons.add,
                text: 'Add Venue',
                onPressed: () {
                  // showDialog(
                  //   context: context,
                  //   builder: (context) {
                  //     return CreateEventPopupView();
                  //   },
                  // );
                  // Handle add event action
                }),
            // AppSpacing.horizontalXs(context),
          ],
        )
      ],
    );
  }
}
