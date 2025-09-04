import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// A utility class that provides consistent border radius values across the application.
/// It handles different radius sizes for both mobile and desktop platforms,
/// ensuring a responsive and unified design system.
///
/// The class provides predefined radius values in different sizes (xs, sm, md, lg, xl)
/// which automatically adjust based on the platform (mobile/desktop) being used.
abstract class AppBorderRadius {
  static const Map<Sizes, double> mobileValues = {
    Sizes.xs: 4.0,
    Sizes.sm: 8.0,
    Sizes.md: 12.0,
    Sizes.lg: 16.0,
    Sizes.xl: 24.0,
  };

  static const Map<Sizes, double> desktopValues = {
    Sizes.xs: 6.0,
    Sizes.sm: 12.0,
    Sizes.md: 16.0,
    Sizes.lg: 20.0,
    Sizes.xl: 32.0,
  };

  /// Returns a [BorderRadius] object with the appropriate radius value based on the platform and size.
  ///
  /// Mobile values:
  /// - xs: 4.0
  /// - sm: 8.0
  /// - md: 12.0
  /// - lg: 16.0
  /// - xl: 24.0
  ///
  /// Desktop values:
  /// - xs: 6.0
  /// - sm: 12.0
  /// - md: 16.0
  /// - lg: 20.0
  /// - xl: 32.0
  ///
  /// [context] The build context used to determine the platform
  /// [size] The desired size variant from the [Sizes] enum
  static BorderRadius radius(BuildContext context, {required Sizes size}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[size]!
        : desktopValues[size]!;
    return BorderRadius.circular(value);
  }
}
