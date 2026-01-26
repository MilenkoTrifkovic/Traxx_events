import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';

/// Service class for managing shared preferences
/// Keep ONLY session-related keys here (auth/user/org).
class SharedPrefServices {
  // Keep keys in one place (so you don’t typo them)
  static const String _kUserRole = 'userRole';

  // ---------------------------
  // UserRole
  // ---------------------------

  Future<void> saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserRole, role.name);
  }

  Future<UserRole?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_kUserRole);
    if (roleString == null) return null;

    return UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.guest, // safe fallback
    );
  }

  Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserRole);
  }

  // ---------------------------
  // ✅ Session reset (logout)
  // ---------------------------

  /// Clears session-related preferences so the next login starts clean.
  /// Add future session keys here (organisationId, userName, tokens, etc.)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove only session keys (recommended)
    await prefs.remove(_kUserRole);

    // If later you store more, add them here:
    // await prefs.remove('organisationId');
    // await prefs.remove('userName');
    // await prefs.remove('companyInfoExists');
  }
}
