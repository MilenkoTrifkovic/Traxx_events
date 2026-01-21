import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// Requires:
/// - ScreenSize.isPhone(context)
/// - ScreenSize.isTablet(context)
/// - ScreenSize.isDesktop(context)
///
/// Uses your existing `Sizes` enum: xs/sm/md/lg/xl
abstract class AppBorderRadius {
  // ✅ Your existing phone values (unchanged)
  static const Map<Sizes, double> mobileValues = {
    Sizes.xs: 4.0,
    Sizes.sm: 8.0,
    Sizes.md: 12.0,
    Sizes.lg: 16.0,
    Sizes.xl: 24.0,
  };

  // ✅ NEW: tablet values (between mobile & desktop)
  static const Map<Sizes, double> tabletValues = {
    Sizes.xs: 5.0,
    Sizes.sm: 10.0,
    Sizes.md: 14.0,
    Sizes.lg: 18.0,
    Sizes.xl: 28.0,
  };

  // ✅ Your existing desktop values (unchanged)
  static const Map<Sizes, double> desktopValues = {
    Sizes.xs: 6.0,
    Sizes.sm: 12.0,
    Sizes.md: 16.0,
    Sizes.lg: 20.0,
    Sizes.xl: 32.0,
  };

  static double _value(BuildContext context, Sizes size) {
    if (ScreenSize.isPhone(context)) return mobileValues[size]!;
    if (ScreenSize.isTablet(context)) return tabletValues[size]!;
    return desktopValues[size]!;
  }

  static BorderRadius radius(BuildContext context, {required Sizes size}) {
    return BorderRadius.circular(_value(context, size));
  }

  // Optional convenience helpers (useful in UI code)
  static double value(BuildContext context, {required Sizes size}) =>
      _value(context, size);

  static BorderRadius only(
    BuildContext context, {
    required Sizes size,
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final v = _value(context, size);
    return BorderRadius.only(
      topLeft: topLeft ? Radius.circular(v) : Radius.zero,
      topRight: topRight ? Radius.circular(v) : Radius.zero,
      bottomLeft: bottomLeft ? Radius.circular(v) : Radius.zero,
      bottomRight: bottomRight ? Radius.circular(v) : Radius.zero,
    );
  }
}
