import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';
import 'package:traxx_wepapp/view/common/event_list_screen.dart';

/// Base controller for event-related functionality.
/// Extend this class to create specific user type controllers (host, guest, etc.)
/// that need event management capabilities.
class EventListController extends GetxController {
  FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  StorageServices storageServices = Get.find<StorageServices>();
  AuthController authController = Get.find<AuthController>();
  var isLoading = false.obs;
  RxList<Event> events = <Event>[].obs;
  RxList<Event> filteredEvents = <Event>[].obs;
  Rxn<Event> selectedEvent = Rxn<Event>();

  String? _loadedOrgId;
  bool _fetchInFlight = false;

  String? get eventId {
    final event = selectedEvent.value;
    return event?.eventId;
  }

  int? get eventCapacity {
    final event = selectedEvent.value;
    return event?.capacity;
  }

  Future<void> copyEventById(
    String sourceEventId, {
    CopyEventOptions? options,
  }) async {
    try {
      isLoading.value = true;

      final source = events.firstWhere((e) => e.eventId == sourceEventId);

      final orgId = authController.organisationId;
      if (orgId == null || orgId.isEmpty) {
        throw Exception('OrganisationId missing');
      }

      final copied = await firestoreServices.copyEventAsDraft(
        source,
        organisationId: orgId,
        options: options,
      );

      final copiedWithUrl = await storageServices.loadImage(copied);
      addCreatedEventToList(copiedWithUrl);
      selectedEvent.value = copiedWithUrl;
    } catch (e) {
      print('copyEventById error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEventById(String eventId) async {
    try {
      final id = eventId.trim();
      if (id.isEmpty) return;

      await firestoreServices.deleteEvent(id);

      // ✅ update local lists (datatable will refresh automatically)
      events.removeWhere((x) => (x.eventId ?? '').trim() == id);
      filteredEvents.removeWhere((x) => (x.eventId ?? '').trim() == id);

      events.refresh();
      filteredEvents.refresh();

      if (selectedEvent.value?.eventId == id) {
        selectedEvent.value = null;
      }

      debugPrint('✅ Deleted event: $id');
    } catch (e) {
      debugPrint('❌ deleteEventById error: $e');
      rethrow;
    }
  }

  Future<void> ensureLoaded(String? orgId, {bool force = false}) async {
    final id = (orgId ?? '').trim();
    if (id.isEmpty) return;

    if (!force && _loadedOrgId == id && events.isNotEmpty) return;
    if (_fetchInFlight) return;

    _loadedOrgId = id;
    await fetchEventsForOrg(id);
  }

  Future<void> fetchEventsForOrg(String orgId) async {
    _fetchInFlight = true;
    isLoading.value = true;
    try {
      var eventsResult = await firestoreServices.getAllEvents(orgId);
      eventsResult = await Future.wait(eventsResult.map((e) async {
        try {
          return await storageServices.loadImage(e);
        } catch (_) {
          return e;
        }
      }));
      events.assignAll(eventsResult);
      filteredEvents.assignAll(eventsResult);
    } finally {
      isLoading.value = false;
      _fetchInFlight = false;
    }
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

  Future<void> publishEventById(String eventId) async {
    final id = eventId.trim();
    if (id.isEmpty) throw Exception('Invalid eventId');

    // Update Firestore first
    await firestoreServices.updateEventStatus(id, EventStatus.published);

    // Update local lists if present
    final i = events.indexWhere((x) => (x.eventId ?? '').trim() == id);
    if (i != -1) {
      events[i] = events[i].copyWith(status: EventStatus.published);
    }

    final fi = filteredEvents.indexWhere((x) => (x.eventId ?? '').trim() == id);
    if (fi != -1) {
      filteredEvents[fi] =
          filteredEvents[fi].copyWith(status: EventStatus.published);
    }

    events.refresh();
    filteredEvents.refresh();

    // Keep selectedEvent in sync if it matches
    if ((selectedEvent.value?.eventId ?? '').trim() == id) {
      selectedEvent.value =
          selectedEvent.value?.copyWith(status: EventStatus.published);
    }
  }

  Future<void> publishEvent() async {
    final current = selectedEvent.value;
    if (current == null) throw Exception('No event selected');
    await publishEventById(current.eventId ?? '');
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
  }
}
