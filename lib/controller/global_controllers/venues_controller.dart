import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';

class VenuesController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();

  // Observable list of venues
  final venues = <Venue>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVenues();
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
      venues.assignAll(allVenues);
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
  void addVenue(Venue venue) {
    venues.add(venue);
  }
}
