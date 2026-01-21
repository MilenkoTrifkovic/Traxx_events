import 'package:package_info_plus/package_info_plus.dart';

class Constants {
  static String appName = 'Trax';

  /// Will be set at startup via [initAppInfo]
  static String traxVersion = '';

  /// Optional: full text like "v1.0.0 (1)"
  static String traxVersionText = '';

  /// Call this once in main() before runApp()
  static Future<void> initAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    traxVersion = info.version; // e.g. "1.0.0"
    traxVersionText =
        'v${info.version} (${info.buildNumber})'; // e.g. "v1.0.0 (1)"
  }

  static const double maxContentWidth = 1600;

  // Configuration
  static const String webClientId =
      '781524162883-udea4nakjljeig3iau98m3m26rhaapj9.apps.googleusercontent.com';

  // Font families
  static const font1 = 'Blanka';
  static const font2 = 'Inter';

  static const String lightLogo = 'assets/icons/light-logo.png';
  static const String darkLogo = 'assets/icons/dark-logo.png';
  static const String cartoonRestaurant =
      'assets/photos/cartoon_restaurant.png';
  static const String emptyMenu = 'assets/photos/empty_menu.png';

  static const String googleMapsApiKey =
      'AIzaSyDt2ZfJjvYxeOHITwVOLG45EqJuQRy9j9o';

  /// Typography scale
  static const double headingLargeFontSize = 32.0;
  static const double headingMediumFontSize = 20.0;
  static const double headingSmallFontSize = 24.0;

  static const double bodyLargeFontSize = 16.0;
  static const double bodyMediumFontSize = 14.0;
  static const double bodySmallFontSize = 12.0;

  static const double labelLargeFontSize = 14.0;
  static const double labelMediumFontSize = 12.0;
  static const double labelSmallFontSize = 11.0;

  /// Letter spacing
  static const double headingLetterSpacing = 1.0;
  static const double bodyLetterSpacing = 0.5;
  static const double labelLetterSpacing = 0.5;

  /// Line height multipliers
  static const double bodyLineHeight = 1.5;
  static const double labelLineHeight = 1.2;

  static const double guestListContainerHeight = 40.0;
}
