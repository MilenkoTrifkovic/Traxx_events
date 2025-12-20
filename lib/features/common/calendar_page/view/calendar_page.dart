import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/controller/calendar_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/widgets/calendar_widget.dart';
import 'package:traxx_wepapp/features/common/calendar_page/widgets/event_list_section.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// Calendar page for viewing and managing events in a calendar view
///
/// This page orchestrates the calendar widget and event list section,
/// managing state and navigation between different views
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Calendar state management
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Get the controllers
  final CalendarController _calendarController = Get.put(CalendarController());
  final EventListController _eventListController =
      Get.find<EventListController>();
  final EventController _eventController = Get.find<EventController>();
  final VenuesController _venuesController = Get.find<VenuesController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  /// Handle navigation to event details
  void _handleEventTap(Event event, Venue venue) {
    _eventListController.selectedEvent.value = event;
    _eventController.setSelectedEvent(event);

    if (_authController.userRole.value == UserRole.admin) {
      pushAndRemoveAllRoute(AppRoute.eventDetails, context,
          urlParam: event.eventId);
    } else {
      pushRoute(AppRoute.guestEventDetails, context,
          urlParam: event.eventId, extra: event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Calendar widget with navigation
          CalendarWidget(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            calendarController: _calendarController,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onPreviousMonth: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month - 1,
                  1,
                );
              });
            },
            onNextMonth: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                  1,
                );
              });
            },
            onTodayPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            onFormatToggle: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.twoWeeks
                    : (_calendarFormat == CalendarFormat.twoWeeks
                        ? CalendarFormat.week
                        : CalendarFormat.month);
              });
            },
          ),

          const SizedBox(height: 24.0),

          // Event list for selected day
          EventListSection(
            selectedDay: _selectedDay,
            calendarController: _calendarController,
            venuesController: _venuesController,
            eventController: _eventController,
            eventListController: _eventListController,
            authController: _authController,
            onEventTap: _handleEventTap,
          ),
        ],
      ),
    );
  }
}
