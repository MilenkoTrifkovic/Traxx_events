import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/controller/calendar_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card.dart';

/// Event list section displaying events for a selected day
///
/// Shows a list of EventCard widgets for the selected date,
/// with venue information and navigation to event details.
class EventListSection extends StatelessWidget {
  final DateTime selectedDay;
  final CalendarController calendarController;
  final VenuesController venuesController;
  final EventController eventController;
  final EventListController eventListController;
  final AuthController authController;
  final Function(Event event, Venue venue) onEventTap;

  const EventListSection({
    super.key,
    required this.selectedDay,
    required this.calendarController,
    required this.venuesController,
    required this.eventController,
    required this.eventListController,
    required this.authController,
    required this.onEventTap,
  });

  /// Build the list of events for the selected day
  Widget _buildEventsList(BuildContext context) {
    final events = calendarController.getEventsForDay(selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48.0,
                color: AppColors.onSurface(context).withOpacity(0.3),
              ),
              const SizedBox(height: 16.0),
              AppText.styledBodyLarge(
                context,
                'No events scheduled for this day',
                color: AppColors.onSurface(context).withOpacity(0.6),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        // Get venue
        final venue = venuesController.getVenueById(event.venueId);
        if (venue == null) {
          print('Warning: Venue not found for event ${event.eventId}');
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < events.length - 1 ? 12.0 : 0.0,
          ),
          child: EventCard(
            event: event,
            venue: venue,
            onTap: () => onEventTap(event, venue),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format the selected date
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
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
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AppText.styledHeadingMedium(
            context,
            'Events on $formattedDate',
            weight: AppFontWeight.bold,
          ),
          const SizedBox(height: 16.0),

          // Events list
          _buildEventsList(context),
        ],
      ),
    );
  }
}
