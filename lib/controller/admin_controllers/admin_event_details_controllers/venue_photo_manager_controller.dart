import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class VenuePhotoManagerController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final VenuesController _venuesController = Get.find<VenuesController>();
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = Get.find<StorageServices>();

  Rxn<Venue> currentVenue = Rxn<Venue>();

  Future<void> removePhotoFromVenue(String venueId, String photoPath) async {
    try {
      showLoadingIndicator(status: 'Removing photo...');

      // Get current venue from Firestore
      Venue venue = await _firestoreServices.getVenueById(venueId);

      // Remove the photo path from the list
      final updatedPhotoPaths = List<String>.from(venue.photoPaths ?? []);
      updatedPhotoPaths.remove(photoPath);

      // Create updated venue
      final updatedVenue = venue.copyWith(photoPaths: updatedPhotoPaths);

      // Update in Firestore first
      await _firestoreServices.updateVenue(updatedVenue);

      // Then update the global controller's local state (this also loads photoUrls)
      final venueWithUrls = await _venuesController.updateVenue(updatedVenue);

      // Force refresh by setting to null first, then the new value
      // This ensures GetX detects the change
      currentVenue.value = null;
      await Future.delayed(const Duration(milliseconds: 50));
      currentVenue.value = venueWithUrls;
    } finally {
      hideLoadingIndicator();
    }
  }

  /// Picks multiple images, uploads them to storage, and adds them to the venue
  ///
  /// Returns the number of photos successfully added, or throws an exception on error
  Future<int> addPhotosToVenue(String venueId) async {
    // 1. Pick multiple images using ImageServices
    final images = await _imageServices.pickMultipleImages();

    if (images.isEmpty) {
      return 0; // User cancelled or no images selected
    }

    try {
      showLoadingIndicator(status: 'Uploading ${images.length} photo(s)...');

      // 2. Get current venue from Firestore
      final venue = await _firestoreServices.getVenueById(venueId);

      // 3. Get current photo paths
      final updatedPhotoPaths = List<String>.from(venue.photoPaths ?? []);

      // 4. Upload each image to Firebase Storage and collect the paths
      int uploadedCount = 0;
      for (int i = 0; i < images.length; i++) {
        try {
          showLoadingIndicator(
              status: 'Uploading photo ${i + 1} of ${images.length}...');
          final storagePath = await _storageServices.uploadImage(images[i]);
          updatedPhotoPaths.add(storagePath);
          uploadedCount++;
          print('Image uploaded successfully: $storagePath');
        } catch (e) {
          print('Failed to upload image: $e');
          // Continue with other images even if one fails
        }
      }

      // 5. Create updated venue with new photo paths
      showLoadingIndicator(status: 'Saving venue...');
      final updatedVenue = venue.copyWith(photoPaths: updatedPhotoPaths);

      // 6. Update in Firestore first
      await _firestoreServices.updateVenue(updatedVenue);

      // 7. Update the global controller's local state (this loads photoUrls)
      final venueWithUrls = await _venuesController.updateVenue(updatedVenue);

      // 8. Force refresh by setting to null first, then the new value
      // This ensures GetX detects the change
      currentVenue.value = null;
      await Future.delayed(const Duration(milliseconds: 50));
      currentVenue.value = venueWithUrls;

      return uploadedCount;
    } finally {
      hideLoadingIndicator();
    }
  }

  void loadVenueById(String venueId) async {
    currentVenue.value =
        _venuesController.venues.firstWhere((v) => v.venueID == venueId);
  }
}
