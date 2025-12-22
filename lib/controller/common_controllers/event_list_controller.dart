import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

/// Base controller for event-related functionality.
/// Extend this class to create specific user type controllers (host, guest, etc.)
/// that need event management capabilities.
class EventListController extends GetxController {
  FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  StorageServices storageServices = Get.find<StorageServices>();
  AuthController authController = Get.find<AuthController>();
  var isLoading = true.obs;
  RxList<Event> events = <Event>[].obs;
  RxList<Event> filteredEvents = <Event>[].obs;
  Rxn<Event> selectedEvent = Rxn<Event>();

  String? get eventId {
    final event = selectedEvent.value;
    return event?.eventId;
  }

  int? get eventCapacity {
    final event = selectedEvent.value;
    return event?.capacity;
  }

  /// Fetches events from Firestore and loads their images from Storage
  Future<void> fetchEvents() async {
    try {
      List<Event> eventsResult =
          await firestoreServices.getAllEvents(authController.organisationId!);
      eventsResult = await Future.wait(
          eventsResult.map((e) => storageServices.loadImage(e)));
      //load urls before assigning to events
      events.assignAll(eventsResult);
    } catch (e) {
      print("Failed to fetch events: $e");
      // rethrow;
    }
    isLoading.value = false;
  }

  /// Filters events based on search text, matching event names
  /// Case-insensitive search that updates filteredEvents in real-time
  void filterEvents(String value) {
    if (value.isEmpty) {
      filteredEvents.assignAll(events);
    } else {
      filteredEvents.assignAll(events.where(
          (event) => event.name.toLowerCase().contains(value.toLowerCase())));
      print('Filtered events count: ${filteredEvents.length}');
    }
  }

  /// Applies multiple filters to the event list
  /// Supports search text, date range, and event type filtering
  void applyFilters({
    String? searchText,
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) {
    var filtered = events.toList();

    // Apply search text filter
    if (searchText != null && searchText.isNotEmpty) {
      filtered = filtered
          .where((event) =>
              event.name.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }

    // Apply date range filter
    if (startDate != null) {
      filtered = filtered
          .where((event) =>
              event.date.isAfter(startDate.subtract(const Duration(days: 1))))
          .toList();
    }

    if (endDate != null) {
      filtered = filtered
          .where((event) =>
              event.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    // Apply event type filter
    if (eventType != null && eventType.isNotEmpty) {
      filtered =
          filtered.where((event) => event.eventType == eventType).toList();
    }

    filteredEvents.assignAll(filtered);
    print('Filtered events count: ${filteredEvents.length}');
  }

  /// Sorts the filtered events list based on the specified sort type
  /// Supports sorting by date (newest/oldest) and name (A-Z/Z-A)
  void sortEvents(SortType sortType) {
    switch (sortType) {
      case SortType.dateNewest:
        filteredEvents.sort(
            (a, b) => _getEventDateTime(b).compareTo(_getEventDateTime(a)));
        break;
      case SortType.dateOldest:
        filteredEvents.sort(
            (a, b) => _getEventDateTime(a).compareTo(_getEventDateTime(b)));
        break;
      case SortType.nameAZ:
        filteredEvents.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZA:
        filteredEvents.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
  }

  /// Helper method to combine date and start time for comparison
  DateTime _getEventDateTime(Event event) {
    return DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      event.startTime.hour,
      event.startTime.minute,
    );
  }

  /// Deletes an event from Firestore and removes it from local lists
  /// Throws Exception if delete operation fails
  Future<void> deleteEvent() async {
    try {
      String eventId = selectedEvent.value!.eventId!;

      await firestoreServices.deleteEvent(eventId);
      events.removeWhere((event) => event.eventId == eventId);
      filteredEvents.assignAll(events);
      print('Event deleted successfully');
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('$e');
    }
  }

  void addCreatedEventToList(Event event) {
    events.add(event);
    filteredEvents.add(event);
    sortEvents(SortType.dateNewest);
  }

  void updateEventInEventList(Event event) {
    int index = events.indexWhere((e) => e.eventId == event.eventId);
    if (index != -1) {
      events[index] = event;
    }
    filteredEvents.assignAll(events);

    sortEvents(SortType.dateNewest);
    if (selectedEvent.value?.eventId == event.eventId) {
      selectedEvent.value = event;
    }
  }

  /// Initializes the controller by fetching events and setting up initial sort
  /// Events are sorted by newest first by default
  @override
  void onInit() {
    super.onInit();
    fetchEvents().then((_) {
      filteredEvents.assignAll(events);
      sortEvents(SortType.dateNewest);
    }).catchError((error) {
      print("Error fetching events: $error");
    });
  }
}
