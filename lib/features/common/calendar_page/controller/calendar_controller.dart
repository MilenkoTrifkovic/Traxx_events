import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/models/event.dart';

/// Controller for managing calendar state and event organization
/// 
/// Handles:
/// - Loading events from EventListController
/// - Organizing events by date for calendar display
/// - Providing events for specific days
class CalendarController extends GetxController {
  // Event storage - maps normalized dates to lists of events
  final RxMap<DateTime, List<Event>> events = RxMap<DateTime, List<Event>>();
  
  // Get the event list controller
  final EventListController _eventListController = Get.find<EventListController>();
  
  @override
  void onInit() {
    super.onInit();
    
    // Load events initially
    loadEvents();
    
    // Listen to changes in the event list and reload
    ever(_eventListController.events, (_) {
      loadEvents();
    });
  }
  
  /// Loads events from the EventListController and organizes them by date
  void loadEvents() {
    // Clear existing events
    events.clear();
    
    // Get all events from the controller
    final allEvents = _eventListController.events;
    
    // Organize events by date (normalized to remove time component)
    for (final event in allEvents) {
      final normalizedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      
      if (events[normalizedDate] == null) {
        events[normalizedDate] = [];
      }
      events[normalizedDate]!.add(event);
    }
  }
  
  /// Returns events for a specific day
  List<Event> getEventsForDay(DateTime day) {
    // Normalize the datetime to ignore time component
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }
}
