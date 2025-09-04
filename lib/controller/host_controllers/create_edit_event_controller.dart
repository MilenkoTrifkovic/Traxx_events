import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  final HostController hostController = Get.find<HostController>();

  final ImageServices _imageServices = ImageServices();

  /// Saves event data to Firestore with optional cover image upload.
  /// Throws Exception if save operation fails.
  Future<void> saveEvent() async {
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
      hostController.addCreatedEvenToList(event); //add event to list
      //Planner Invite
      print('Event saved successfully');
    } catch (e) {
      print('Error saving event: $e');
      throw Exception('$e');
    }
  }

  /// Updates an existing event in Firestore with optional cover image upload.
  /// Throws Exception if update operation fails.
  Future<void> updateEvent() async {
    try {
      final Event event = Event.fromFormState(formState);
      event.id = hostController.selectedEvent.value!.id;

      //if user selected new image it will overwrite the old one
      if (formState.coverImage != null) {
        String imagePath =
            await storageServices.uploadImage(formState.coverImage!);
        event.coverImageUrl = imagePath;
        await storageServices.loadImage(event);
      } else {
        event.coverImageUrl = hostController.selectedEvent.value?.coverImageUrl;
        event.coverImageDownloadUrl =
            hostController.selectedEvent.value?.coverImageDownloadUrl;
      }
      await firestoreServices.updateEvent(event);
      // hostController.addCreatedEvent(event); //add event to list
      hostController.updateEventInEventList(event); //Update event in list
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
