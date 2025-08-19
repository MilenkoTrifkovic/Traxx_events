import 'package:get/get.dart';

/// Temporary auth controller for testing purposes only.
/// TODO: Replace with actual authentication implementation.
class AuthController extends GetxController {
  var isLoading = true.obs;
  var userName = 'User'.obs; //actual name will be loaded from user data

  Future<void> checkAuth() async {
    // load user info, events...
    await Future.delayed(Duration(seconds: 1)); // example
    isLoading.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  void logout() {
    // Implement logout logic
  }
}
