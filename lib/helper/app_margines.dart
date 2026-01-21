import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// Requires:
/// - ScreenSize.isPhone(context)
/// - ScreenSize.isTablet(context)
/// - ScreenSize.isDesktop(context)
///
/// Uses your existing `Sizes` enum.
abstract class AppMargins {
  // ✅ Your existing phone values (unchanged)
  static const Map<Sizes, double> mobileValues = {
    Sizes.xs: 4.0,
    Sizes.sm: 8.0,
    Sizes.md: 16.0,
    Sizes.lg: 24.0,
    Sizes.xl: 32.0,
  };

  // ✅ NEW: tablet values (between mobile & desktop)
  static const Map<Sizes, double> tabletValues = {
    Sizes.xs: 6.0,
    Sizes.sm: 10.0,
    Sizes.md: 18.0,
    Sizes.lg: 26.0,
    Sizes.xl: 34.0,
  };

  // ✅ Your existing desktop values (unchanged)
  static const Map<Sizes, double> desktopValues = {
    Sizes.xs: 8.0,
    Sizes.sm: 12.0,
    Sizes.md: 20.0,
    Sizes.lg: 28.0,
    Sizes.xl: 36.0,
  };

  static double _value(BuildContext context, Sizes type) {
    if (ScreenSize.isPhone(context)) return mobileValues[type]!;
    if (ScreenSize.isTablet(context)) return tabletValues[type]!;
    return desktopValues[type]!;
  }

  static EdgeInsets all(BuildContext context, {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.all(v);
  }

  static EdgeInsets horizontal(BuildContext context,
      {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.symmetric(horizontal: v);
  }

  static EdgeInsets vertical(BuildContext context,
      {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.symmetric(vertical: v);
  }

  static EdgeInsets bottom(BuildContext context, {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.only(bottom: v);
  }

  static EdgeInsets top(BuildContext context, {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.only(top: v);
  }

  static EdgeInsets left(BuildContext context, {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.only(left: v);
  }

  static EdgeInsets right(BuildContext context, {required Sizes marginType}) {
    final v = _value(context, marginType);
    return EdgeInsets.only(right: v);
  }

  static EdgeInsets only(
    BuildContext context, {
    required Sizes marginType,
    bool left = false,
    bool top = false,
    bool right = false,
    bool bottom = false,
  }) {
    final v = _value(context, marginType);
    return EdgeInsets.only(
      left: left ? v : 0,
      top: top ? v : 0,
      right: right ? v : 0,
      bottom: bottom ? v : 0,
    );
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    Sizes? horizontalMargin,
    Sizes? verticalMargin,
  }) {
    final h =
        horizontalMargin == null ? 0.0 : _value(context, horizontalMargin);
    final v = verticalMargin == null ? 0.0 : _value(context, verticalMargin);

    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }
}
