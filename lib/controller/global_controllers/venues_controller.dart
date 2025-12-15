import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class VenuesController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  // Observable list of venues
  final venues = <Venue>[].obs;
  // final Map<String, List<Ven>> menusByVenue = {};
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVenues();
  }

  Future<List<Venue>> _withPhotoUrls(List<Venue> venueList) async {
    return Future.wait(venueList.map((v) async {
      String? singlePhotoUrl = v.photoUrl;
      List<String>? multiplePhotoUrls = v.photoUrls;

      // Load single photoUrl if not already set
      if (singlePhotoUrl == null && v.photoPath != null) {
        singlePhotoUrl = await _storageServices.loadImageURL(v.photoPath);
      }

      // Load multiple photoUrls if photoPaths exist and photoUrls not set
      if (multiplePhotoUrls == null &&
          v.photoPaths != null &&
          v.photoPaths!.isNotEmpty) {
        multiplePhotoUrls = [];
        for (final path in v.photoPaths!) {
          final url = await _storageServices.loadImageURL(path);
          if (url != null) {
            multiplePhotoUrls.add(url);
          }
        }
      }

      // Return updated venue only if we actually fetched something new
      if (singlePhotoUrl != v.photoUrl || multiplePhotoUrls != v.photoUrls) {
        return v.copyWith(
          photoUrl: singlePhotoUrl,
          photoUrls: multiplePhotoUrls,
        );
      }

      return v;
    }));
  }

  /// Loads all venues from Firestore and updates the observable list
  Future<void> loadVenues() async {
    try {
      isLoading.value = true;
      // You may want to pass organisationId as a parameter or get it from another controller
      // For now, assuming organisationId is available globally
      final organisationId = _authController.organisationId!;
      print('Organisation ID in VenuesController: $organisationId');
      final allVenues = await _firestoreServices.getVenues(organisationId);
      final withUrls = await _withPhotoUrls(allVenues);
      print('Loaded with URLs: ${withUrls.length} venues');
      print('List of venue IDs: ${withUrls.map((v) => v.photoUrls).toList()}');
      venues.assignAll(withUrls);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error loading venues: $e');
      // Handle error as needed
    }
  }

  Venue? getVenueById(String venueId) {
    try {
      return venues.firstWhere((venue) => venue.venueID == venueId);
    } catch (e) {
      print('Venue with ID $venueId not found: $e');
      return null;
    }
  }

  /// Fetches a venue by ID, tries local list first, then Firestore, and handles errors.
  Future<Venue?> fetchVenueById(String venueId) async {
    Venue? venue = getVenueById(venueId);
    if (venue != null) return venue;
    try {
      venue = await _firestoreServices.getVenueById(venueId);
      return venue;
    } catch (e) {
      print('Error fetching venue: $e');
      return null;
    }
  }

  /// Adds a new venue to the observable list
  Future<void> addVenue(Venue venue) async {
    // _withPhotoUrls returns copies with photoUrl set when possible.
    final updatedList = await _withPhotoUrls([venue]);
    final updated = updatedList.isNotEmpty ? updatedList.first : venue;
    venues.add(updated);
  }

  /// Deletes a venue from Firestore and updates local cache
  Future<bool> removeVenue(String venueId) async {
    try {
      showLoadingIndicator();

      // Delete the document in Firestore
      await _firestoreServices.deleteVenue(venueId);
      venues.removeWhere((venue) => venue.venueID == venueId);

      // Clear from any cached menu lists (menusByVenue)
      // menusByVenue.forEach((key, list) {
      //   list.removeWhere((m) => m.venueId == venueId);
      // });

      // If you keep other local lists of menu items elsewhere, remove from them too.
      // print('Menu item $menuItemId deleted and cache cleared.');
      snackbarMessageController
          .showSuccessMessage('Venue deleted successfully!');
      return true;
    } catch (e) {
      // print('Failed to remove menu item $menuItemId: $e');
      snackbarMessageController.showErrorMessage('Failed to delete venue: $e');
      return false;
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<Venue> updateVenue(Venue updatedVenue) async {
    try {
      // Find the index of the existing venue
      final index =
          venues.indexWhere((venue) => venue.venueID == updatedVenue.venueID);

      // Check if venue exists
      if (index == -1) {
        throw Exception(
            'Venue with ID ${updatedVenue.venueID} not found in local list');
      }

      // Load photo URLs if needed
      Venue venueToUpdate = updatedVenue;
      String? singlePhotoUrl = updatedVenue.photoUrl;
      List<String>? multiplePhotoUrls = updatedVenue.photoUrls;
      print('single: $singlePhotoUrl');
      print('multiple: $multiplePhotoUrls');

      // Load single photoUrl if not already set
      if (updatedVenue.photoPath != null && singlePhotoUrl == null) {
        print('Loading single photo URL for venue ID: ${updatedVenue.venueID}');
        singlePhotoUrl =
            await _storageServices.loadImageURL(updatedVenue.photoPath!);
      }

      // Load multiple photoUrls if photoPaths exist and photoUrls not set
      if (updatedVenue.photoPaths != null &&
          updatedVenue.photoPaths!.isNotEmpty &&
          multiplePhotoUrls == null) {
        print(
            'Loading multiple photo URLs for venue ID: ${updatedVenue.venueID}');
        multiplePhotoUrls = [];
        for (final path in updatedVenue.photoPaths!) {
          final url = await _storageServices.loadImageURL(path);
          if (url != null) {
            multiplePhotoUrls.add(url);
          }
        }
      }

      // Update venue with loaded URLs
      if (singlePhotoUrl != updatedVenue.photoUrl ||
          multiplePhotoUrls != updatedVenue.photoUrls) {
        venueToUpdate = updatedVenue.copyWith(
          photoUrl: singlePhotoUrl,
          photoUrls: multiplePhotoUrls,
        );
      }

      // Update the venue in the observable list
      venues[index] = venueToUpdate;

      // Optional: Force UI update by reassigning the list
      // venues.value = List.from(venues);

      return venueToUpdate;
    } catch (e) {
      print('Failed to update venue in local list: $e');
      rethrow;
    }
  }
}
