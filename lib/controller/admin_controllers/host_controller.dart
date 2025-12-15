import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
// import 'package:traxx_wepapp/services/firestore_services.dart';
// import 'package:traxx_wepapp/services/storage_services.dart';

class HostController {
  RxBool isEditingEvent = false.obs;

  // final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  // final StorageServices _storageServices = Get.find<StorageServices>();
  Rxn<Event> selectedEvent = Rxn<Event>();
  final errorMessage = ''.obs;
  RxBool isLoading = false.obs;

  void toggleEditingEvent(bool state) {
    isEditingEvent.value = state;
  }

  void setEvent(Event event) async {
    try {
      isLoading.value = true;
      selectedEvent.value = event;
      return;
    } on FirebaseException {
      errorMessage.value = 'Error loading event';
    } catch (e) {
      errorMessage.value = 'Unexpected error';
      print('Error fetching event by ID: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }
  // Future<void> setEvent(String eventId, {Event? event}) async {
  //   try {
  //     isLoading.value = true;
  //     if (event != null) {
  //       selectedEvent.value = event;
  //       return;
  //     } else {
  //       Event loadedEvent = await _firestoreServices.getEventById(eventId);
  //       loadedEvent = await _storageServices.loadImage(loadedEvent);
  //       selectedEvent.value = loadedEvent;
  //     }
  //   } on FirebaseException catch (e) {
  //     errorMessage.value = 'Error loading event';
  //   } catch (e) {
  //     errorMessage.value = 'Unexpected error';
  //     print('Error fetching event by ID: ${errorMessage.value}');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void updateSelectedEvent(Event event) {
    selectedEvent.value = event;
  }
}
