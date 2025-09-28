import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/mixins/selected_event_mixin.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class GuestController extends GetxController with SelectedEventMixin {
  // final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  // final StorageServices _storageServices = Get.find<StorageServices>();
  // Rxn<Event> selectedEvent = Rxn<Event>();
  final errorMessage = ''.obs;
  // RxBool isLoading = false.obs;

  // Future<void> setEvent(String eventId, {Event? event}) async {
  // Future<void> setEvent(Event event) async {
  // void setEvent(Event event) async {
  //   try {
  //     isLoading.value = true;
  //     // if (event != null) {
  //     selectedEvent.value = event;
  //     return;
  //     // } else {
  //     //   Event loadedEvent = await _firestoreServices.getEventById(eventId);
  //     //   loadedEvent = await _storageServices.loadImage(loadedEvent);
  //     //   selectedEvent.value = loadedEvent;
  //     // }
  //   } on FirebaseException catch (e) {
  //     errorMessage.value = 'Error loading event';
  //   } catch (e) {
  //     errorMessage.value = 'Unexpected error';
  //     print('Error fetching event by ID: ${errorMessage.value}');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  //guest Responses
}
