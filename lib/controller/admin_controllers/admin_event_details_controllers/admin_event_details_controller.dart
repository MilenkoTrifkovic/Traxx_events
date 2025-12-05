import 'dart:math';

import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/menus_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';

class AdminEventDetailsController {
  /// Loads selected menu items from availableMenuItems based on event.selectedMenus

  final OrganisationController _organisationController =
      Get.find<OrganisationController>();
  final EventsController _eventsController = Get.find<EventsController>();
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final VenuesController _venuesController = Get.find<VenuesController>();
  final MenusController _menusController = Get.find<MenusController>();

  Event? event;
  Venue? venue;
  Organisation? organisation;
  List<MenuItem> availableMenuItems = [];
  Rx<List<MenuItem>> selectedMenusEvent = Rx<List<MenuItem>>([]);
  Rx<List<MenuItem>> selectedMenusLocally = Rx<List<MenuItem>>([]);
  Rx<List<MenuItem>> availableMenus = Rx<List<MenuItem>>([]);

  Future<void> loadEvent(String eventId) async {
    event = await _eventsController.fetchEventById(eventId);
    if (event != null) {
      await _loadVenue(event!.venueId);
      await _loadOrganisation(event!.organisationId);
      await _assignAvailableMenuItems();
      await _assignAvailableMenus();
      _loadSelectedMenuItems();
    }
  }

  /// Removes a menu item from selectedMenuItems and event.selectedMenus
  void removeMenuItemFromSelection(MenuItem item) {
    // selectedMenusFirestore.value = selectedMenusFirestore.value
    //     .where((i) => i.menuItemId != item.menuItemId)
    //     .toList();
    selectedMenusLocally.value = selectedMenusLocally.value
        .where((i) => i.menuItemId != item.menuItemId)
        .toList();
    event?.selectedMenus?.remove(
        item.menuItemId); //////////////////////////////////////////////////
    print('Removed:${item.menuItemId} ${event?.selectedMenus}');
  }

  /// Adds a menu item to event.selectedMenus and selectedMenuItems
  void addMenuItemToSelection(MenuItem item) {
    if (event == null || item.menuItemId == null) return;
    event!.selectedMenus ??= <String>[];
    if (!event!.selectedMenus!.contains(item.menuItemId!)) {
      event!.selectedMenus!.add(item.menuItemId!);
      // selectedMenusFirestore.value = [...selectedMenusFirestore.value, item];
      selectedMenusLocally.value = [...selectedMenusLocally.value, item];
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
      availableMenuItems = await _menusController
          .getMenuItemsByOrganisationId(event!.organisationId);
    } catch (e) {
      availableMenuItems = [];
    }
  }

  Future<void> _assignAvailableMenus() async {
    if (event?.venueId == null) return;
    try {
      availableMenus.value = await _menusController
          .getMenuItemsByOrganisationId(event!.organisationId);
    } catch (e) {
      availableMenus.value = [];
    }
  }

  void _loadSelectedMenuItems() {
    selectedMenusEvent.value = availableMenuItems
        .where((item) => event!.selectedMenus!.contains(item.menuItemId))
        .toList();
    selectedMenusLocally.value = selectedMenusEvent.value;
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

  void syncSelectedMenusLists() {
    selectedMenusLocally.value = List<MenuItem>.from(selectedMenusEvent.value);
    event?.selectedMenus =
        selectedMenusEvent.value.map((item) => item.menuItemId!).toList();
  }

  void dispose() {
    // Dispose resources if needed
  }
}
