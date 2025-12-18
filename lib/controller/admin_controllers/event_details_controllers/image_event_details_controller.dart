import 'dart:ui';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class ImageEventDetailsController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final StorageServices _storageServices = Get.find<StorageServices>();
  Future<void> deleteEventImage(Event event) async {
    try {
      if (event.coverImageUrl == null || event.coverImageUrl!.isEmpty) {
        print('No image to delete for event ${event.eventId}');
        return;
      }
      showLoadingIndicator(status: 'Deleting image...');
      _firestoreServices.updateEvent(event.copyWith(coverImageUrl: ''));
      print('Image deleted successfully for event ${event.eventId}');
    } catch (e) {
      print('Failed to delete image for event ${event.eventId}: $e');
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<void> uploadEventImage(Event event, Function(Event) onUpdate) async {
    try {
      ImagePicker picker = ImagePicker();
      final XFile? pickedImage =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) {
        print('No image selected for event ${event.eventId}');
        return;
      }
      showLoadingIndicator(status: 'Uploading image...');
      final uploadTask = await _storageServices.uploadImage(pickedImage);
      _firestoreServices.updateEvent(event.copyWith(coverImageUrl: uploadTask));
      onUpdate(event.copyWith(coverImageUrl: uploadTask));
      print('Image uploaded successfully for event ${event.eventId}');
    } catch (e) {
      print('Failed to upload image for event ${event.eventId}: $e');
    } finally {
      hideLoadingIndicator();
    }
  }
}
