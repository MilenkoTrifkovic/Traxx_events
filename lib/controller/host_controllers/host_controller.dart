import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/SortType.dart';

class HostController extends GetxController {
  FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  StorageServices storageServices = Get.find<StorageServices>();
  var isLoading = true.obs;
  RxList<Event> events = <Event>[].obs;
  RxList<Event> filteredEvents = <Event>[].obs;

  /// Fetches events from Firestore and loads their images from Storage
  Future<void> fetchEvents() async {
    try {
      List<Event> eventsResult = await firestoreServices.getAllEvents();
      eventsResult = await Future.wait(
          eventsResult.map((e) => storageServices.loadImage(e)));
      events.assignAll(eventsResult);
      print("Events fetched successfully: ${events[0].toString()}");
    } catch (e) {
      print("Failed to fetch events: $e");
      // rethrow;
    }
    isLoading.value = false;
    // filteredEvents.assignAll(events);
  }

  /// Filters events based on search text, matching event names
  /// Case-insensitive search that updates filteredEvents in real-time
  void filterEvents(String value) {
    if (value.isEmpty) {
      filteredEvents.assignAll(events);
    } else {
      filteredEvents.assignAll(events.where(
          (event) => event.name.toLowerCase().contains(value.toLowerCase())));
    }
  }

  /// Sorts the filtered events list based on the specified sort type
  /// Supports sorting by date (newest/oldest) and name (A-Z/Z-A)
  void sortEvents(SortType sortType) {
    switch (sortType) {
      case SortType.dateNewest:
        filteredEvents
            .sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        break;
      case SortType.dateOldest:
        filteredEvents
            .sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        break;
      case SortType.nameAZ:
        filteredEvents.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZA:
        filteredEvents.sort((a, b) => b.name.compareTo(a.name));
        break;
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
