import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/enums/user_role.dart';

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

  Future<void> checkCompanyInfo() async {
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
  }

  Future<void> refreshCompanyInfo() async {
    await checkCompanyInfo();
  }

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

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _isAuthenticated.value = user != null;

      if (user != null) {
        await checkOrganisationForCurrentUser();
      } else {
        _companyInfoExists.value = false;
        organisationId = null;
      }

      // IMPORTANT: stop the global loader
      isLoading.value = false;
    });
  }

  Future<void> logout() async {
    try {
      print('Starting logout process...');

      userRole.value = null;
      organisation.value = null;
      organisationId = null;
      _companyInfoExists.value = false;
      userName.value = 'User';

      _sharedPrefServices.clearUserRole();
      await FirebaseAuth.instance.signOut();

      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}


/* class AuthController extends GetxController {
  late final FirestoreServices _firestoreServices;
  late final SharedPrefServices _sharedPrefServices;
  late final CloudFunctionsService _cloudFunctionsService;

  // private reactive flags
  final RxBool _isAuthenticated = false.obs;
  final RxBool _companyInfoExists = false.obs;

  // public bool getters
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

  // --- SETTERS for internal use / other services ---

  void setOrganisationInfoExists(bool value) {
    _companyInfoExists.value = value; // ✅ use RxBool internally
  }

  void setAuthenticated(bool value) {
    _isAuthenticated.value = value; // ✅ use RxBool internally
  }

  // ------------------------------------------------------------------
  // USER ROLE
  // ------------------------------------------------------------------

  void setUserType(UserRole type) {
    userRole.value = UserRole.admin;
    _sharedPrefServices.saveUserRole(type);
  }

  Future<void> loadUserType() async {
    UserRole? type = await _sharedPrefServices.getUserRole();
    if (type != null) {
      userRole.value = type;
      print('Controller registered for user type:$type');
    }
  }

  // ------------------------------------------------------------------
  // ORGANISATION CHECK (new flow)
  // ------------------------------------------------------------------

  Future<void> checkOrganisationForCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      _companyInfoExists.value = false;
      organisationId = null;
      return;
    }

    // 1️⃣ Check canonical user doc: /users/{uid}
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final orgIdFromUser = data?['organisationId'] as String?;

    if (orgIdFromUser != null && orgIdFromUser.isNotEmpty) {
      organisationId = orgIdFromUser;
      _companyInfoExists.value = true;
      print('✅ organisationId from user doc: $organisationId');
      return;
    }

    // 2️⃣ Optional fallback to CF for old accounts
    final response = await _cloudFunctionsService.checkOrganisationInfo();
    _companyInfoExists.value = response.hasOrganisation;
    organisationId = response.organisationId;
    print('Company info check fallback: $response');
  }

  // ------------------------------------------------------------------
  // AUTH / COMPANY INFO
  // ------------------------------------------------------------------

  Future<void> checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }

  bool get isAuthenticatedAndVerified {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.emailVerified;
  }

  Future<void> checkCompanyInfo() async {
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
  }

  Future<void> refreshCompanyInfo() async {
    await checkCompanyInfo();
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

  // ------------------------------------------------------------------
  // LISTEN TO AUTH CHANGES
  // ------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _isAuthenticated.value = user != null; // ✅ use RxBool directly

      if (user != null) {
        await checkOrganisationForCurrentUser();
      } else {
        _companyInfoExists.value = false; // ✅
        organisationId = null;
      }
    });
  }

  // ------------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------------

  Future<void> logout() async {
    try {
      print('Starting logout process...');

      userRole.value = null;
      organisation.value = null;
      organisationId = null;
      _companyInfoExists.value = false; // ✅
      userName.value = 'User';

      _sharedPrefServices.clearUserRole();
      await FirebaseAuth.instance.signOut();

      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
 */