import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

class EventListHeader extends StatelessWidget {
  EventListHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Events'),
        Row(
          children: [
            if (ScreenSize.isDesktop(context) == true)
              AppSearchInputField(
                hintText: 'Search events...',
                onChanged: (value) {
                  eventListController.filterEvents(value);
                },
              ),
            AppSpacing.horizontalXs(context),
            AppPrimaryButton(
                icon: Icons.add,
                text: 'Add Event',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return CreateEventPopupView();
                    },
                  );
                  // Handle add event action
                }),
            // AppSpacing.horizontalXs(context),
          ],
        )
      ],
    );
  }
}
