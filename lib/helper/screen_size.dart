// import 'package:flutter/material.dart';

// abstract class ScreenSize {
//   static bool isPhone(BuildContext context) =>
//       MediaQuery.of(context).size.width < 600;

//   static bool isTablet(BuildContext context) =>
//       MediaQuery.of(context).size.width >= 600 &&
//       MediaQuery.of(context).size.width < 1200;

//   static bool isDesktop(BuildContext context) =>
//       MediaQuery.of(context).size.width >= 1200;
// }

import 'package:flutter/material.dart';

abstract class ScreenSize {
  // Breakpoints (tweak any number you want)
  static const double phoneXs = 360;
  static const double phoneSm = 480;
  static const double phone = 600;

  static const double tabletSm = 768;
  static const double tablet = 1024;

  static const double desktop = 1200;
  static const double desktopLg = 1440;
  static const double ultra = 1920;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isPhone(BuildContext context) => width(context) < phone;

  static bool isTablet(BuildContext context) =>
      width(context) >= phone && width(context) < desktop;

  static bool isDesktop(BuildContext context) => width(context) >= desktop;

  // Extra helpers (optional but useful)
  static bool isSmallPhone(BuildContext context) => width(context) < phoneXs;
  static bool isLargePhone(BuildContext context) =>
      width(context) >= phoneXs && width(context) < phone;

  static bool isTabletPortrait(BuildContext context) =>
      width(context) >= phone && width(context) < tabletSm;

  static bool isTabletLandscape(BuildContext context) =>
      width(context) >= tabletSm && width(context) < desktop;

  static bool isLargeDesktop(BuildContext context) =>
      width(context) >= desktopLg && width(context) < ultra;

  static bool isUltraWide(BuildContext context) => width(context) >= ultra;

  /// Generic picker (super helpful for spacing/padding/etc.)
  static T pick<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    required T desktop,
    T? largeDesktop,
    T? ultra,
  }) {
    final w = width(context);
    if (w < ScreenSize.phone) return phone;
    if (w < ScreenSize.desktop) return tablet ?? desktop;
    if (w < ScreenSize.desktopLg) return desktop;
    if (w < ScreenSize.ultra) return largeDesktop ?? desktop;
    return ultra ?? (largeDesktop ?? desktop);
  }

  /// For tables: decide when to switch to "card list"
  static bool useCompactTable(BuildContext context) => width(context) < 900;
}
