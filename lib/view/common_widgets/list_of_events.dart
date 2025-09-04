import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/common_widgets/event_card.dart';

/// A widget that displays a scrollable list of events using EventCard widgets.
class ListOfEvents extends StatelessWidget {
  const ListOfEvents({
    super.key,
  });

  /// Builds a reactive list view that updates when the filtered events change.
  /// Shows a "No events found" message when the list is empty.
  @override
  Widget build(BuildContext context) {
    // HostController hostController = Get.find<HostController>();
    final controller = Get.find<HostController>();
    return Obx(() {
      if (controller.filteredEvents.isEmpty) {
        return Center(child: Text('No events found'));
      }

      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: controller.filteredEvents.length,
          itemBuilder: (context, index) {
            final event = controller.filteredEvents[index];
            return EventCard(
              event: event,
              onTap: () {
                controller.selectedEvent.value = event;
                pushRoute(AppRoute.eventDetails, context);
              },
            );
          },
        ),
      );
    });
  }
}
