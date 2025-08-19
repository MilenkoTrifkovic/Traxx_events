import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

/// Controller for managing event creation operations
class CreateEventController {
  final EventFormState formState = Get.find<EventFormState>();
  final FirestoreServices firestoreServices = Get.find<FirestoreServices>();
  final StorageServices storageServices = Get.find<StorageServices>();

  final ImageServices _imageServices = ImageServices();

  /// Saves event data to Firestore with optional cover image upload.
  /// Throws Exception if save operation fails.
  Future<void> saveEvent() async {
    try {
      final Event event = Event.fromFormState(formState);
      if (formState.coverImage != null) {
        String imagePath =
            await storageServices.uploadImage(formState.coverImage!);
        event.coverImageUrl = imagePath;
      }
      await firestoreServices.saveEvent(event);
      //Planner Invite
      print('Event saved successfully');
    } catch (e) {
      print('Error saving event: $e');
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
