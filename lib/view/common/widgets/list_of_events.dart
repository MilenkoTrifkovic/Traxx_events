import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';

/// A widget that displays a scrollable list of events using EventCard widgets.
class ListOfEvents extends StatelessWidget {
  const ListOfEvents({
    super.key,
  });

  /// Builds a reactive list view that updates when the filtered events change.
  /// Shows a "No events found" message when the list is empty.

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.find<AuthController>();
    final EventListController controller = Get.find<EventListController>();
    final EventController eventController = Get.find<EventController>();

    return Obx(() {
      if (controller.filteredEvents.isEmpty && controller.events.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height -
              200, // Give it most of the screen height
          child: EmptyState(
            title: 'Welcome to Traxx',
            description: 'Lets create your first event',
            buttonText: 'Add First Event',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CreateEventPopupView();
                },
              );
            },
          ),
        );
      }
      if (controller.filteredEvents.isEmpty) {
        return Center(child: Text('No filtered events found'));
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredEvents.length,
        itemBuilder: (context, index) {
          final event = controller.filteredEvents[index];
          return Padding(
            padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
            child: EventCard(
              event: event,
              onTap: () {
                print(  'Event tapped: ${event.name} (ID: ${event.eventId})${event.toString()}');
                controller.selectedEvent.value = event;
                eventController.setSelectedEvent(event);
                if (authController.userRole.value == UserRole.admin) {
                  pushAndRemoveAllRoute(AppRoute.eventDetails, context,
                      urlParam: event.eventId);
                } else {
                  pushRoute(AppRoute.guestEventDetails, context,
                      urlParam: event.eventId, extra: event);
                }
              },
            ),
          );
        },
      );
    });
  }
}
