import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxx_wepapp/utils/enums/user_role.dart';

/// Service class for managing shared preferences
/// Currently handles saving and retrieving user role.
class SharedPrefServices {
  void saveUserRole(UserRole role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role.name);
  }

  Future<UserRole?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleString = prefs.getString('userRole');
    if (roleString != null) {
      return UserRole.values.firstWhere(
        (e) => e.name == roleString,
      );
    }
    return null;
  }

  void clearUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
  }
}
