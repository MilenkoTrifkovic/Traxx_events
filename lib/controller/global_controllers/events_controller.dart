import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';

class EventsController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable list of events
  final events = <Event>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  /// Loads all events from Firestore and updates the observable list
  Future<void> loadEvents() async {
    try {
      isLoading.value = true;
      final organisationId = _authController.organisationId!;
      print('Organisation ID in EventsController: $organisationId');
      final allEvents = await _firestoreServices.getAllEvents(organisationId);
      events.assignAll(allEvents);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error loading events: $e');
      // Handle error as needed
    }
  }

  Event? getEventById(String eventId) {
    try {
      return events.firstWhere((event) => event.eventId == eventId);
    } catch (e) {
      print('Event with ID $eventId not found: $e');
      return null;
    }
  }

  /// Fetches an event by ID, tries local list first, then Firestore, and handles errors.
  Future<Event?> fetchEventById(String eventId) async {
    Event? event = getEventById(eventId);
    if (event != null) return event;
    try {
      event = await _firestoreServices.getEventById(eventId);
      return event;
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  /// Adds a new event to the observable list
  void addEvent(Event event) {
    events.add(event);
  }
}
