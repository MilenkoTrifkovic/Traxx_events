import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

class AuthController extends GetxController {
  late final FirestoreServices _firestoreServices;
  late final SharedPrefServices _sharedPrefServices;
  late final CloudFunctionsService _cloudFunctionsService;

  final RxBool _isAuthenticated = false.obs;
  final RxBool _companyInfoExists = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;
  bool get companyInfoExists => _companyInfoExists.value;

  String? organisationId;
  var userName = 'User'.obs;
  var isLoading = true.obs;
  var userRole = Rx<UserRole?>(null);
  var organisation = Rxn<Organisation>();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  AuthController()
      : _sharedPrefServices = Get.find<SharedPrefServices>(),
        _firestoreServices = Get.find<FirestoreServices>(),
        _cloudFunctionsService = Get.find<CloudFunctionsService>() {
    print('New AuthController created');
  }

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _isAuthenticated.value = user != null;

      if (user != null) {
        await loadUserProfile();
      } else {
        organisationId = null;
        userRole.value = null;
        organisation.value = null;
      }

      isLoading.value = false;
    });
  }

  void setOrganisationInfoExists(bool value) {
    _companyInfoExists.value = value;
  }

  void setAuthenticated(bool value) {
    _isAuthenticated.value = value;
  }

  Future<void> fetchOrganisation() async {
    if (organisationId == null || organisationId!.isEmpty) {
      print('Organisation ID is null or empty, cannot fetch organisation');
      organisation.value = null;
      return;
    }

    try {
      print('Fetching organisation with ID: $organisationId');
      final org = await _firestoreServices.getOrganisation(organisationId!);
      organisation.value = org;
      print('Organisation fetched successfully: ${org.name}');
    } catch (e) {
      print('Error fetching organisation: $e');
      organisation.value = null;
    }
  }

  /*  Future<void> checkCompanyInfo() async {
    if (!isAuthenticatedAndVerified) {
      print(
          'User not authenticated or not verified, skipping company info check');
      _companyInfoExists.value = false; // ✅ use RxBool
      return;
    }

    try {
      print('Checking company info existence...');

      final response = await _cloudFunctionsService.checkOrganisationInfo();
      print('Company info check response: $response');

      _companyInfoExists.value = response.hasOrganisation; // ✅
      print('Company info exists? ${_companyInfoExists.value}');
      print('response- hasOrganisation: ${response.hasOrganisation}');

      userRole.value = response.role != null
          ? UserRole.values.firstWhere((e) => e.name == response.role)
          : null;
      organisationId = response.organisationId;
      print('Company info exists: ${response.hasOrganisation}');

      if (organisationId != null && organisationId!.isNotEmpty) {
        await fetchOrganisation();
      }
    } catch (e) {
      print('Error checking company info: $e');
      _companyInfoExists.value = false; // ✅
    }
  } */

  /*  Future<void> refreshCompanyInfo() async {
    await checkCompanyInfo();
  } */

  // ───────────────────────────────────────────────────────────────
  // NEW: check org by looking at Firestore users/{uid}
  // ───────────────────────────────────────────────────────────────

  Future<void> checkOrganisationForCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      _companyInfoExists.value = false;
      organisationId = null;
      return;
    }

    // Prefer Firestore users/{uid}.organisationId
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    final orgIdFromUser = data?['organisationId'] as String?;

    if (orgIdFromUser != null && orgIdFromUser.isNotEmpty) {
      organisationId = orgIdFromUser;
      _companyInfoExists.value = true;
      print('✅ Found organisationId on users/${user.uid}: $orgIdFromUser');
      return;
    }

    // Optional cloud function fallback (can also be removed later)
    final response = await _cloudFunctionsService.checkOrganisationInfo();
    _companyInfoExists.value = response.hasOrganisation;
    organisationId = response.organisationId;
  }

  bool get isAuthenticatedAndVerified {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.emailVerified;
  }

  Future<void> loadUserProfile() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) {
      // User exists in Firebase Auth but not in Firestore yet.
      // This only happens for FIRST signup before handleNewUser runs.
      userRole.value = UserRole.guest;
      organisationId = null;
      _companyInfoExists.value = false;
      organisation.value = null;
      return;
    }

    final data = userDoc.data()!;
    final roleString = data['role'] as String? ?? 'guest';
    final orgId = data['organisationId'] as String?;

    userRole.value = UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.guest,
    );

    organisationId = orgId;

    // ✅ THIS is what your router is reading
    _companyInfoExists.value =
        organisationId != null && organisationId!.isNotEmpty;

    // Load organisation details if exists
    if (organisationId != null && organisationId!.isNotEmpty) {
      try {
        organisation.value =
            await _firestoreServices.getOrganisation(organisationId!);
      } catch (_) {
        organisation.value = null;
      }
    } else {
      organisation.value = null;
    }
  }

/*   Future<void> loadUserProfile() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) {
      // User exists in Firebase Auth but not in Firestore yet.
      // This only happens for FIRST signup before handleNewUser runs.
      userRole.value = UserRole.guest;
      organisationId = null;
      return;
    }

    final data = userDoc.data()!;
    final roleString = data['role'] as String? ?? 'guest';
    final orgId = data['organisationId'] as String?;

    userRole.value = UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.guest,
    );

    organisationId = orgId;

    // Load organisation details if exists
    if (organisationId != null && organisationId!.isNotEmpty) {
      try {
        organisation.value =
            await FirestoreServices().getOrganisation(organisationId!);
      } catch (_) {
        organisation.value = null;
      }
    }
  }
 */
  bool get isVerified =>
      firebaseAuth.currentUser != null &&
      firebaseAuth.currentUser!.emailVerified;

  Future<void> logout() async {
    await firebaseAuth.signOut();

    organisationId = null;
    userRole.value = null;
    organisation.value = null;
  }
}
