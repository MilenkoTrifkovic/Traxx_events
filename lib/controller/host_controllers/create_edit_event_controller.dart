import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

/// Controller for managing event creation operations
class CreateEditEventController {
  final EventFormState formState = Get.find<EventFormState>();
  final FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  final StorageServices storageServices = Get.find<StorageServices>();
  final EventListController eventListController =
      Get.find<EventListController>();
  final HostController hostController = Get.find<HostController>();

  final ImageServices _imageServices = ImageServices();

  /// Saves event data to Firestore with optional cover image upload.
  /// Throws Exception if save operation fails.
  Future<Event> saveEvent() async {
    try {
      print('Saving event...form State: ${formState.toString()}');
      final Event event = Event.fromFormState(formState);
      print('Saving event...event State: ${event.toString()}');

      if (formState.coverImage != null) {
        String imagePath =
            await storageServices.uploadImage(formState.coverImage!);
        event.coverImageUrl = imagePath;
        await storageServices.loadImage(
            event); //gets download URL so event can be added to list without needing to refetch
      }
      await firestoreServices.saveEvent(event);
      eventListController.addCreatedEvenToList(event); //add event to list
      print('Event saved successfully');
      return event;
      //Planner Invite
    } catch (e) {
      print('Error saving event: $e');
      throw Exception('$e');
    }
  }

  /// Updates an existing event in Firestore with optional cover image upload.
  /// Throws Exception if update operation fails.
  Future<void> updateEvent(Event eventa) async {
    try {
      final Event event = Event.fromFormState(formState);
      event.id = eventa.id;
      print('Event from form state: ${event.toString()}');
      print('Event passed: ${eventa.toString()}');

      //if user selected new image it will overwrite the old one
      if (formState.coverImage != null) {
        String imagePath =
            await storageServices.uploadImage(formState.coverImage!);
        event.coverImageUrl = imagePath;
        await storageServices.loadImage(event);
      } else {
        event.coverImageUrl = eventa.coverImageUrl;
        event.coverImageDownloadUrl = eventa.coverImageDownloadUrl;
      }
      await firestoreServices.updateEvent(event);
      eventListController.updateEventInEventList(
          event); //updates event in host controller for event details
      hostController.updateSelectedEvent(
          event); //updates event in event list controller for event list

      //Planner Invite
      print('Event updated successfully');
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('$e');
    }
  }

  /// Loads a cover image from gallery and updates form state.
  /// Returns the picked image or null if no image was selected.
  Future<XFile?> loadCoverImage() async {
    XFile? pickedImage = await _imageServices.pickImage(ImageSource.gallery);
    if (pickedImage != null) {
      formState.coverImage = pickedImage;
      return pickedImage;
    }
    return null;
  }
}
