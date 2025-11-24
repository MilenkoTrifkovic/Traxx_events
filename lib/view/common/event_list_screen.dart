import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/common/widgets/event_list_header.dart';
import 'package:traxx_wepapp/view/common/widgets/list_of_events.dart';
import 'package:traxx_wepapp/view/common/widgets/search_field.dart';
import 'package:traxx_wepapp/view/common/widgets/sort_events.dart';

/// A screen that displays a list of events for the host user.
///
/// This screen includes:
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
/// - The behavior of the list items depends on the logged in user type (host/guest).
class EventListScreen extends StatelessWidget {
  EventListScreen({super.key});
  EventListController eventListController = Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    // Build the main layout with scrolling and padding
    // return Row(
    //   children: [Text('data')],
    // );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search and sort controls row
          Row(
            children: [
              // Search field that expands to fill available space
              // Expanded(child: SearchField()),
              // Sort button with dropdown options

              // SORT EVENTS
              // SortEvents(),
            ],
          ),
          // Vertical spacing between controls and list
          // AppSpacing.verticalMd(context),
          // List of event cards
          Obx(() => Container(
              decoration: BoxDecoration(
                color: eventListController.filteredEvents.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Column(
                  children: [
                    if (eventListController.filteredEvents.isNotEmpty)
                      EventListHeader(),
                    AppSpacing.verticalXxxs(context),
                    const ListOfEvents(),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}
