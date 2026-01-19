import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class OrganisationController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();

  final organisation = Rxn<Organisation>();
  final RxBool isInitialized = false.obs;
  final isLoading = false.obs;
  final String organisationId;
  final RxBool showMenuItemPrices = true.obs;

  OrganisationController(this.organisationId);

  @override
  void onInit() {
    super.onInit();
    if (organisationId.isNotEmpty) {
      loadOrganisation(organisationId);
    }
  }

  /// Loads organisation by ID and updates the observable
  Future<void> loadOrganisation(String organisationId) async {
    print('Loading organisation image for logo path: ');
    try {
      isLoading.value = true;
      final org = await _firestoreServices.getOrganisation(organisationId);
      showMenuItemPrices.value = org.showMenuItemPrices ?? true;
      // Load photo download URL from Storage if a logo path exists.
      try {
        if (org.logo != null && org.logo!.isNotEmpty) {
          final storage = Get.find<StorageServices>();
          final downloadUrl = await storage.loadImageURL(org.logo);
          print('Loaded organisation image URL: $downloadUrl');
          organisation.value = org.copyWith(photoUrl: downloadUrl);
        } else {
          organisation.value = org;
        }
        isInitialized.value = true;
      } catch (e) {
        // If image loading fails, still set the organisation without photoUrl
        print('Failed to load organisation image: $e');
        organisation.value = org;
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error loading organisation: $e');
      // keep old organisation value if exists
      isInitialized.value = true; // <- important!
    }
  }

  Future<void> updateShowMenuItemPrices(bool v) async {
    if (organisationId.isEmpty) return;

    isLoading.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('organisations')
          .doc(organisationId)
          .update({'showMenuItemPrices': v});

      // ✅ 1) update reactive flag for instant UI refresh
      showMenuItemPrices.value = v;

      // ✅ 2) keep local org model in sync
      final current = organisation.value;
      if (current != null) {
        organisation.value = current.copyWith(showMenuItemPrices: v);
      }
    } catch (e) {
      print('Failed to update showMenuItemPrices: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Organisation? getOrganisation() {
    return organisation.value;
  }

  /// Gets the organisation name or returns a default placeholder
  String getOrganisationName() {
    return organisation.value?.name ?? 'Event Manager';
  }

  /// Gets the organisation logo/photo URL if available
  String? getOrganisationPhotoUrl() {
    return organisation.value?.photoUrl;
  }

  /// Adds or updates the organisation
  void setOrganisation(Organisation org) {
    organisation.value = org;
  }

  /// Updates organisation via Firestore and updates local observable on success.
  /// Returns true if update succeeded, false otherwise.
  Future<bool> updateOrganisation(Organisation org) async {
    try {
      print(  'Updating organisation: ${org.toJson()}');
      // isLoading.value = true;
      final updated = await _firestoreServices.updateOrganisation(org);
      organisation.value = updated;
      // isLoading.value = false;
      return true;
    } catch (e) {
      // isLoading.value = false;
      print('Error updating organisation: $e');
      return false;
    }
  }

  void clearOrganisation() {
    organisation.value = null;
  }
}
