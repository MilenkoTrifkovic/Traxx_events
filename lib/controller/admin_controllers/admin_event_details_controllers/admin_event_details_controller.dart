import 'dart:math';

import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';

class AdminEventDetailsController {
  /// Loads selected menu items from availableMenuItems based on event.selectedMenus

  final OrganisationController _organisationController =
      Get.find<OrganisationController>();
  final EventsController _eventsController = Get.find<EventsController>();
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final VenuesController _venuesController = Get.find<VenuesController>();

  Event? event;
  Venue? venue;
  Organisation? organisation;
  List<MenuItem> availableMenuItems = [];
  List<MenuItem> selectedMenuItems = [];

  Future<void> loadEvent(String eventId) async {
    event = await _eventsController.fetchEventById(eventId);
    if (event != null) {
      await _loadVenue(event!.venueId);
      await _loadOrganisation(event!.organisationId);
      await _assignAvailableMenuItems();
      _loadSelectedMenuItems();
    }
  }

  /// Adds a menu item to event.selectedMenus and selectedMenuItems
  void addMenuItemToSelection(MenuItem item) {
    if (event == null || item.menuItemId == null) return;
    event!.selectedMenus ??= <String>[];
    if (!event!.selectedMenus!.contains(item.menuItemId!)) {
      event!.selectedMenus!.add(item.menuItemId!);
      selectedMenuItems.add(item);
    }
    print('Added:${item.menuItemId} ${event!.selectedMenus}');
  }

  Future<void> _loadVenue(String venueId) async {
    venue = await _venuesController.fetchVenueById(venueId);
  }

  Future<void> _loadOrganisation(String organisationId) async {
    organisation = _organisationController.getOrganisation();
  }

  /// Loads and assigns available menu items for the event's venue
  Future<void> _assignAvailableMenuItems() async {
    if (event?.venueId == null) return;
    try {
      availableMenuItems =
          await _venuesController.getEventMenusByVenueId(event!.venueId);
    } catch (e) {
      availableMenuItems = [];
    }
  }

  void _loadSelectedMenuItems() {
    selectedMenuItems = availableMenuItems
        .where((item) => event!.selectedMenus!.contains(item.menuItemId))
        .toList();
  }

  /// Persists the currently loaded event to Firestore and updates
  /// the global events list in [EventsController].
  Future<void> updateEvent() async {
    if (event == null) {
      throw Exception('Cannot update event: no event loaded');
    }

    if (event!.eventId == null) {
      throw Exception('Cannot update event: eventId is null');
    }

    try {
      await _firestoreServices.updateEvent(event!);
      print('Event updated in Firestore: ${event!.toString()}');

      final index = _eventsController.events
          .indexWhere((e) => e.eventId == event!.eventId);
      if (index != -1) {
        _eventsController.events[index] = event!;
      }
      _loadSelectedMenuItems();

      print('Admin event details updated successfully: ${event!.eventId}');
    } catch (e) {
      print('Error updating event from admin details: $e');
      rethrow;
    }
  }

  void dispose() {
    // Dispose resources if needed
  }
}
