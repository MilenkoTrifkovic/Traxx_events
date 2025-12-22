import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_list_header_old.dart';
import 'package:traxx_wepapp/view/common/widgets/list_of_events.dart';

/// A screen that displays a list of events for the host user.
///
/// This screen includes:
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
/// - The behavior of the list items depends on the logged in user type (host/guest).
class EventListScreen extends StatelessWidget {
  EventListScreen({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Event list container
          Obx(() => Container(
              decoration: BoxDecoration(
                color: eventListController.events.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Column(
                  children: [
                    // Show header and filters if there are any events in the system
                    if (eventListController.events.isNotEmpty) ...[
                      // EventListHeader(),
                      AppSpacing.verticalXs(context),
                      EventFilterSection(),
                      AppSpacing.verticalXs(context),
                    ],
                    const ListOfEvents(),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}
