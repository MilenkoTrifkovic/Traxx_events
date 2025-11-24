import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

/// Temporary auth controller for testing purposes only.
/// TODO: Replace with actual authentication implementation.
class AuthController extends GetxController {
  late final FirestoreServices _firestoreServices;
  late final SharedPrefServices _sharedPrefServices;
  late final CloudFunctionsService _cloudFunctionsService;
  Rx<bool> companyInfoExists = false.obs;

  String? organisationId;
  var userName = 'User'.obs;
  var isLoading = true.obs;
  var userRole = Rx<UserRole?>(null);
  var organisation = Rxn<Organisation>();
  // var userRole = UserRole.admin.obs;
  //actual name will be loaded from user data
  AuthController()
      : _sharedPrefServices = Get.find<SharedPrefServices>(),
        _firestoreServices = Get.find<FirestoreServices>(),
        _cloudFunctionsService = Get.find<CloudFunctionsService>() {
    print('New AuthController created');
    //constructor
  }
  void setOrganisationInfoExists(bool exists) {
    companyInfoExists.value = exists;
  }

//temporary method
  void setUserType(UserRole type) {
    userRole.value = UserRole.admin;
    // userType.value = type;
    // _registerController(type);
    _sharedPrefServices.saveUserRole(type);
  }

  Future<void> loadUserType() async {
    UserRole? type = await _sharedPrefServices.getUserRole();
    if (type != null) {
      userRole.value = type;
      // _registerController(type);
      print('Controller registered for user type:$type');
    }
  }

  // void _registerController(UserType type) {
  //   if (Get.isRegistered<EventListController>()) {
  //     Get.delete<EventListController>();
  //   }

  // }

  Future<void> checkAuth() async {
    // load user info, events...
    await Future.delayed(Duration(seconds: 1)); // example
    isLoading.value = false;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Check if user is authenticated and verified
  bool get isAuthenticatedAndVerified {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.emailVerified;
  }

  /// Checks if company/organisation info exists for the current user
  /// and updates the companyInfoExists reactive variable
  /// Only works if user is authenticated
  Future<void> checkCompanyInfo() async {
    if (!isAuthenticatedAndVerified) {
      print(
          'User not authenticated or not verified, skipping company info check');
      companyInfoExists.value = false;
      return;
    }

    try {
      print('Checking company info existence...');

      // Call the cloud function through the service
      final response = await _cloudFunctionsService.checkOrganisationInfo();
      print('Company info check response: $response');
      // Update the reactive variable
      companyInfoExists.value = response.hasOrganisation;
      print('Company info exists? ${companyInfoExists.value}');
      print('response- hasOrganisation: ${response.hasOrganisation}');
      userRole.value = response.role != null
          ? UserRole.values.firstWhere((e) => e.name == response.role)
          : null;
      organisationId = response.organisationId;
      print('Company info exists: ${response.hasOrganisation}');

      // Fetch organisation data if organisationId is available
      if (organisationId != null && organisationId!.isNotEmpty) {
        await fetchOrganisation();
      }
    } catch (e) {
      print('Error checking company info: $e');

      // Set to false if there's an error
      companyInfoExists.value = false;

      // Optionally rethrow or handle the error as needed
      // rethrow;
    }
  }

  /// Method to manually refresh company info status
  /// Can be called after creating/updating organisation info
  Future<void> refreshCompanyInfo() async {
    await checkCompanyInfo();
  }

  /// Fetches organisation data and updates the organisation observable
  /// Should be called after organisationId is set
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
      // Optionally rethrow or handle the error as needed
      // rethrow;
    }
  }

  @override
  void onInit() {
    super.onInit();
    checkAuth();
    loadUserType();
  }

  /// Logs out the current user and cleans up app state
  Future<void> logout() async {
    try {
      print('Starting logout process...');

      // Reset controller state first
      userRole.value = null;
      organisation.value = null;
      organisationId = null;
      companyInfoExists.value = false;
      userName.value = 'User';

      // Clear local data
      _sharedPrefServices.clearUserRole();

      // Sign out from Firebase Auth last
      await FirebaseAuth.instance.signOut();

      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
      // Don't rethrow to avoid blocking navigation
    }
  }
  // Future<void> createOrganisation({
  //   required String name,
  //   required String phone,
  //   String? website,
  //   required String street,
  //   required String city,
  //   required String state,
  //   required String zip,
  //   required String country,
  //   required String timezone,
  //   String? logo,
  // }) async {
  //   try {
  //     // Create the organisation model here
  //     final organisation = Organisation(
  //       // organisationId will be assigned by cloud function
  //       name: name,
  //       phone: phone,
  //       website: website,
  //       street: street,
  //       city: city,
  //       state: state,
  //       zip: zip,
  //       country: country,
  //       timezone: timezone,
  //       logo: logo,
  //       createdAt: DateTime.now(),
  //       modifiedDate: DateTime.now(),
  //       isDisabled: false,
  //     );

  //     // TODO: Save to Firestore using your service
  //     // await firestoreService.createOrganisation(organisation);
  //     await _firestoreServices.addOrganisation(organisation);

  //     print('Organisation created: ${organisation.name}');
  //   } catch (e) {
  //     print('Error creating organisation: $e');
  //     rethrow;
  //   }
  // }
}
