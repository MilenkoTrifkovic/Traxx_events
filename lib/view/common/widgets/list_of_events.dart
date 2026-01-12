import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/list_of_events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_event_popup_view.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';

/// A widget that displays a scrollable list of events using EventCard widgets.
class ListOfEvents extends StatefulWidget {
  const ListOfEvents({super.key});

  @override
  State<ListOfEvents> createState() => _ListOfEventsState();
}

class _ListOfEventsState extends State<ListOfEvents> {
  late final AuthController authController;
  late final EventListController controller;
  late final EventController eventController;
  late final VenuesController venuesController;

  // If you might have multiple ListOfEvents in the tree, using a tag avoids conflicts.
  late final String _tag;
  late final ListOfEventsController paginationController;

  @override
  void initState() {
    super.initState();

    authController = Get.find<AuthController>();
    controller = Get.find<EventListController>();
    eventController = Get.find<EventController>();
    venuesController = Get.find<VenuesController>();

    _tag = 'ListOfEvents_${identityHashCode(this)}';

    // Put only once (initState), not on every build.
    paginationController = Get.isRegistered<ListOfEventsController>(tag: _tag)
        ? Get.find<ListOfEventsController>(tag: _tag)
        : Get.put(ListOfEventsController(), tag: _tag);
  }

  @override
  void dispose() {
    // Clean up only if this controller is meant to be owned by this widget.
    if (Get.isRegistered<ListOfEventsController>(tag: _tag)) {
      Get.delete<ListOfEventsController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading indicator while venues or events are loading
      if (venuesController.isLoading.value || controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredEvents.isEmpty && controller.events.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: EmptyState(
            title: 'Welcome to Trax',
            description: 'Lets create your first event',
            buttonText: 'Add First Event',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (_) => CreateEventPopupView(),
              );
            },
          ),
        );
      }

      if (controller.filteredEvents.isEmpty) {
        return SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                AppText.styledHeadingSmall(
                  context,
                  'No events found',
                  weight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                AppText.styledBodyMedium(
                  context,
                  'Try adjusting your filters',
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      }

      final paginatedEvents =
          paginationController.getPaginatedEvents(controller.filteredEvents);
      final totalPages =
          paginationController.getTotalPages(controller.filteredEvents);

      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedEvents.length,
            itemBuilder: (context, index) {
              final event = paginatedEvents[index];
              final venue = venuesController.getVenueById(event.venueId);

              // Skip rendering if venue is not found
              if (venue == null) {
                print(
                  'Warning: Venue not found for event ${event.eventId} with venueId ${event.venueId}',
                );
                return const SizedBox.shrink();
              }

              return Padding(
                padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
                child: EventCard(
                  venue: venue,
                  event: event,
                  onTap: () {
                    controller.selectedEvent.value = event;
                    eventController.setSelectedEvent(event);

                    if (authController.userRole.value == UserRole.admin) {
                      pushAndRemoveAllRoute(
                        AppRoute.eventDetails,
                        context,
                        urlParam: event.eventId,
                      );
                    } else {
                      pushRoute(
                        AppRoute.guestEventDetails,
                        context,
                        urlParam: event.eventId,
                        extra: event,
                      );
                    }
                  },
                ),
              );
            },
          ),
          if (totalPages > 1)
            Padding(
              padding: AppPadding.all(context, paddingType: Sizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: paginationController.hasPreviousPage
                        ? () => paginationController.previousPage()
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    paginationController
                        .getPaginationText(controller.filteredEvents),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: paginationController
                            .hasNextPage(controller.filteredEvents)
                        ? () => paginationController.nextPage(
                              controller.filteredEvents,
                            )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
