import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';

class OrganisationController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();

  final organisation = Rxn<Organisation>();
  final isLoading = false.obs;
  final String organisationId;

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
    try {
      isLoading.value = true;
      final org = await _firestoreServices.getOrganisation(organisationId);
      organisation.value = org;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      organisation.value = null;
      print('Error loading organisation: $e');
    }
  }

  Organisation? getOrganisation() {
    return organisation.value;
  }

  /// Adds or updates the organisation
  void setOrganisation(Organisation org) {
    organisation.value = org;
  }

  void clearOrganisation() {
    organisation.value = null;
  }
}
