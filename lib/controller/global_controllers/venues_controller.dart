import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/loader.dart';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class VenuesController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final AuthController _authController = Get.find<AuthController>();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  // Observable list of venues
  final venues = <Venue>[].obs;
  final isLoading = false.obs;

  // Optional: cache first photo url for fast tile rendering
  final RxMap<String, String> firstPhotoUrlByVenueId = <String, String>{}.obs;

  String? _loadedOrgId;
  bool _fetchInFlight = false;
  final RxnString loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    // ✅ Safe: will do nothing until orgId exists
    Future.microtask(() => ensureLoaded(_authController.organisationId));
  }

  /// ✅ Call this from HostShell after orgId is ready.
  /// Safe to call multiple times.
  Future<void> ensureLoaded(String? orgId, {bool force = false}) async {
    final id = (orgId ?? '').trim();
    if (id.isEmpty) return;

    if (_fetchInFlight) return; // ✅ important

    if (!force && _loadedOrgId == id && venues.isNotEmpty) return;

    _loadedOrgId = id;
    await loadVenuesForOrg(id, force: force);
  }

  Future<void> refreshForOrg(String? orgId) async {
    await ensureLoaded(orgId, force: true);
  }

  /// Backward compatible: old method name used by some pages
  Future<void> loadVenues() async {
    await ensureLoaded(_authController.organisationId, force: true);
  }

  // ─────────────────────────────────────────────
  // Photo URL helpers
  // ─────────────────────────────────────────────

  Future<List<Venue>> _withPhotoUrls(List<Venue> venueList) async {
    return Future.wait(venueList.map((v) async {
      String? singlePhotoUrl = v.photoUrl;
      Map<String, String>? photoPathToUrlMap = v.photoPathToUrlMap;

      // Load single photoUrl if not already set
      if ((singlePhotoUrl == null || singlePhotoUrl.trim().isEmpty) &&
          v.photoPath != null &&
          v.photoPath!.trim().isNotEmpty) {
        singlePhotoUrl = await _storageServices.loadImageURL(v.photoPath!);
      }

      // Load multiple photoUrls if photoPaths exist and map not set
      if ((photoPathToUrlMap == null || photoPathToUrlMap.isEmpty) &&
          v.photoPaths != null &&
          v.photoPaths!.isNotEmpty) {
        final Map<String, String> map = {};
        for (final path in v.photoPaths!) {
          final p = path.trim();
          if (p.isEmpty) continue;
          final url = await _storageServices.loadImageURL(p);
          if (url != null && url.trim().isNotEmpty) {
            map[p] = url.trim();
          }
        }
        if (map.isNotEmpty) {
          photoPathToUrlMap = map;
        }
      }

      // Return updated venue only if we actually fetched something new
      final changedSingle = singlePhotoUrl != v.photoUrl;
      final changedMap = photoPathToUrlMap != v.photoPathToUrlMap;

      if (changedSingle || changedMap) {
        return v.copyWith(
          photoUrl: singlePhotoUrl,
          photoPathToUrlMap: photoPathToUrlMap,
        );
      }

      return v;
    }));
  }

  Future<void> _primeFirstPhotoUrls(List<Venue> venueList) async {
    final Map<String, String> next =
        Map<String, String>.from(firstPhotoUrlByVenueId);

    for (final v in venueList) {
      final id = (v.venueID ?? '').trim();
      if (id.isEmpty) continue;

      // prefer already resolved single
      String? url = v.photoUrl;

      // else map’s first
      if ((url ?? '').trim().isEmpty) {
        final map = v.photoPathToUrlMap;
        if (map != null && map.isNotEmpty) {
          url = map.values.first;
        }
      }

      // else resolve first path
      if ((url ?? '').trim().isEmpty) {
        final ref = (v.photoPaths != null && v.photoPaths!.isNotEmpty)
            ? v.photoPaths!.first
            : (v.photoPath ?? '');
        if (ref.trim().isNotEmpty) {
          url = await _storageServices.loadImageURL(ref);
        }
      }

      if ((url ?? '').trim().isNotEmpty) {
        next[id] = url!.trim();
      } else {
        next.remove(id);
      }
    }

    firstPhotoUrlByVenueId.assignAll(next);
  }

  // ─────────────────────────────────────────────
  // Load Venues (reload-safe)
  // ─────────────────────────────────────────────

  Future<void> loadVenuesForOrg(String orgId, {bool force = false}) async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;

    isLoading.value = true;
    try {
      loadError.value = null;

      final allVenues = await _firestoreServices.getVenues(orgId);
      final withUrls = await _withPhotoUrls(allVenues);

      venues.assignAll(withUrls);

      // Optional: prime tile cache
      await _primeFirstPhotoUrls(withUrls);
    } catch (e, st) {
      debugPrint('Error loading venues: $e');
      debugPrint('$st');
      loadError.value = e.toString();
      venues.clear();
      firstPhotoUrlByVenueId.clear();
    } finally {
      isLoading.value = false;
      _fetchInFlight = false;
    }
  }

  // ─────────────────────────────────────────────
  // CRUD helpers
  // ─────────────────────────────────────────────

  Venue? getVenueById(String venueId) {
    try {
      return venues.firstWhere((v) => v.venueID == venueId);
    } catch (_) {
      return null;
    }
  }

  Future<Venue?> fetchVenueById(String venueId) async {
    final local = getVenueById(venueId);
    if (local != null) return local;

    try {
      final fetchedVenue = await _firestoreServices.getVenueById(venueId);
      final withUrls = await _withPhotoUrls([fetchedVenue]);
      final v = withUrls.isNotEmpty ? withUrls.first : fetchedVenue;

      await _primeFirstPhotoUrls([v]);
      return v;
    } catch (e) {
      debugPrint('Error fetching venue: $e');
      return null;
    }
  }

  Future<void> addVenue(Venue venue) async {
    final updatedList = await _withPhotoUrls([venue]);
    final updated = updatedList.isNotEmpty ? updatedList.first : venue;

    venues.add(updated);
    await _primeFirstPhotoUrls([updated]);
  }

  Future<bool> removeVenue(String venueId) async {
    try {
      showLoadingIndicator();

      await _firestoreServices.deleteVenue(venueId);

      venues.removeWhere((v) => v.venueID == venueId);
      firstPhotoUrlByVenueId.remove(venueId);

      snackbarMessageController
          .showSuccessMessage('Venue deleted successfully!');
      return true;
    } catch (e) {
      snackbarMessageController.showErrorMessage('Failed to delete venue: $e');
      return false;
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<Venue> updateVenue(Venue updatedVenue) async {
    try {
      final index = venues.indexWhere((v) => v.venueID == updatedVenue.venueID);
      if (index == -1) {
        throw Exception(
            'Venue with ID ${updatedVenue.venueID} not found in local list');
      }

      final withUrls = await _withPhotoUrls([updatedVenue]);
      final v = withUrls.isNotEmpty ? withUrls.first : updatedVenue;

      venues[index] = v;
      await _primeFirstPhotoUrls([v]);

      return v;
    } catch (e) {
      debugPrint('Failed to update venue in local list: $e');
      rethrow;
    }
  }

  /// Optional: clear on logout
  void clearCache() {
    venues.clear();
    firstPhotoUrlByVenueId.clear();
    _loadedOrgId = null;
    loadError.value = null;
  }
}
