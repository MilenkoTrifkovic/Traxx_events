import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

/// Helper class for fetching and processing events
class EventFetcher {
  /// Efficiently fetches an event either from memory or Firestore.
  /// If [event] is provided, returns it directly to avoid unnecessary database calls.
  /// If [event] is null, fetches the event from Firestore using the [eventId].
  ///
  /// Returns a Future<Event> that resolves to either the provided event or the fetched event.
  static Future<Event> fetchEvent(String eventId) async {
    FirestoreServices firestoreServices = Get.find<FirestoreServices>();
    StorageServices storageServices = Get.find<StorageServices>();
    Event fetchedEvent = await firestoreServices.getEventById(eventId);
    fetchedEvent = await storageServices
        .loadImage(fetchedEvent); //load image url from storage
    return fetchedEvent;
  }
}
