import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class VenuesController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();
  final StorageServices _storageServices = Get.find<StorageServices>();

  // Observable list of venues
  final venues = <Venue>[].obs;
  final Map<String, List<MenuItem>> menusByVenue = {};
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVenues();
  }

  // /// Returns cached menu items for a venue if available, otherwise fetches from Firestore, caches, and returns them.
  // Future<List<MenuItem>> getEventMenusByVenueId(String venueId) async {
  //   // Check cache first
  //   if (menusByVenue.containsKey(venueId)) {
  //     return menusByVenue[venueId]!;
  //   }
  //   // Fetch from Firestore
  //   final menuList = await _firestoreServices.getMenuItemsByVenueId(venueId);

  //   menusByVenue[venueId] = menuList;
  //   return menuList;
  // }
  Future<List<MenuItem>> getEventMenusByVenueId(String venueId) async {
    if (menusByVenue.containsKey(venueId)) {
      return menusByVenue[venueId]!;
    }
    final menuList = await _firestoreServices.getMenuItemsByVenueId(venueId);
    final updated = await _withImageUrls(menuList);
    menusByVenue[venueId] = updated;
    return updated;
  }

  Future<List<MenuItem>> _withImageUrls(List<MenuItem> menuList) async {
    return Future.wait(menuList.map((item) async {
      if (item.imageUrl != null || item.imagePath == null) return item;
      final url = await _storageServices.loadImageURL(item.imagePath);
      if (url == null) return item;
      return item.copyWith(imageUrl: url);
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
