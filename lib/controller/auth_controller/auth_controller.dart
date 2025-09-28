import 'package:get/get.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

/// Temporary auth controller for testing purposes only.
/// TODO: Replace with actual authentication implementation.
class AuthController extends GetxController {
  late final SharedPrefServices _sharedPrefServices;
  var isLoading = true.obs;
  var userName = 'User'.obs;
  var userType = UserType.guest.obs;
  //actual name will be loaded from user data
  AuthController() : _sharedPrefServices = Get.find<SharedPrefServices>() {
    //constructor
  }

//temporary method
  void setUserType(UserType type) {
    userType.value = type;
    // _registerController(type);
    _sharedPrefServices.saveUserRole(type);
  }

  Future<void> loadUserType() async {
    UserType? type = await _sharedPrefServices.getUserRole();
    if (type != null) {
      userType.value = type;
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

  @override
  void onInit() {
    super.onInit();
    checkAuth();
    loadUserType();
  }

  void logout() {
    // Implement logout logic
  }
}
