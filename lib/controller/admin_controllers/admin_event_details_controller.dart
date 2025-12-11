// import 'dart:math';

// import 'package:get/get.dart';
// import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
// import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
// import 'package:traxx_wepapp/models/event.dart';
// import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
// import 'package:traxx_wepapp/models/organisation.dart';
// import 'package:traxx_wepapp/models/venue.dart';

// class AdminEventDetailsController {
//   final OrganisationController _organisationController =
//       Get.find<OrganisationController>();
//   final EventsController _eventsController = Get.find<EventsController>();
//   // final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
//   final VenuesController _venuesController = Get.find<VenuesController>();

//   Event? event;
//   Venue? venue;
//   Organisation? organisation;

//   Future<void> loadEvent(String eventId) async {
//     event = await _eventsController.fetchEventById(eventId);
//     if (event != null) {
//       await _loadVenue(event!.venueId);
//       await _loadOrganisation(event!.organisationId);
//     }
//   }

//   Future<void> _loadVenue(String venueId) async {
//     venue = await _venuesController.fetchVenueById(venueId);
//   }

//   Future<void> _loadOrganisation(String organisationId) async {
//     organisation = _organisationController.getOrganisation();
//   }

//   void dispose() {
//     // Dispose resources if needed
//   }
// }
