import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

abstract class AppPadding {
  // ✅ Your existing phone values (unchanged)
  static const Map<Sizes, double> mobileValues = {
    Sizes.xxxxs: 2.0,
    Sizes.xxxs: 4.0,
    Sizes.xxs: 6.0,
    Sizes.xs: 8.0,
    Sizes.sm: 12.0,
    Sizes.md: 16.0,
    Sizes.lg: 20.0,
    Sizes.xl: 24.0,
    Sizes.xxl: 28.0,
    Sizes.xxxl: 32.0,
    Sizes.xxxxl: 40.0,
    Sizes.xxxxxl: 56.0,
  };

  // ✅ NEW: tablet values (between mobile & desktop)
  static const Map<Sizes, double> tabletValues = {
    Sizes.xxxxs: 3.0,
    Sizes.xxxs: 6.0,
    Sizes.xxs: 9.0,
    Sizes.xs: 12.0,
    Sizes.sm: 18.0,
    Sizes.md: 24.0,
    Sizes.lg: 30.0,
    Sizes.xl: 36.0,
    Sizes.xxl: 42.0,
    Sizes.xxxl: 48.0,
    Sizes.xxxxl: 60.0,
    Sizes.xxxxxl: 84.0,
  };

  // ✅ Your existing desktop values (unchanged)
  static const Map<Sizes, double> desktopValues = {
    Sizes.xxxxs: 4.0,
    Sizes.xxxs: 8.0,
    Sizes.xxs: 12.0,
    Sizes.xs: 16.0,
    Sizes.sm: 24.0,
    Sizes.md: 32.0,
    Sizes.lg: 40.0,
    Sizes.xl: 48.0,
    Sizes.xxl: 56.0,
    Sizes.xxxl: 64.0,
    Sizes.xxxxl: 80.0,
    Sizes.xxxxxl: 112.0,
  };

  static double _value(BuildContext context, Sizes type) {
    if (ScreenSize.isPhone(context)) return mobileValues[type]!;
    if (ScreenSize.isTablet(context)) return tabletValues[type]!;
    return desktopValues[type]!;
  }

  static EdgeInsets all(BuildContext context, {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.all(v);
  }

  static EdgeInsets horizontal(BuildContext context,
      {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.symmetric(horizontal: v);
  }

  static EdgeInsets vertical(BuildContext context,
      {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.symmetric(vertical: v);
  }

  static EdgeInsets bottom(BuildContext context, {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.only(bottom: v);
  }

  static EdgeInsets top(BuildContext context, {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.only(top: v);
  }

  static EdgeInsets left(BuildContext context, {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.only(left: v);
  }

  static EdgeInsets right(BuildContext context, {required Sizes paddingType}) {
    final v = _value(context, paddingType);
    return EdgeInsets.only(right: v);
  }

  static EdgeInsets only(
    BuildContext context, {
    required Sizes paddingType,
    bool left = false,
    bool top = false,
    bool right = false,
    bool bottom = false,
  }) {
    final v = _value(context, paddingType);
    return EdgeInsets.only(
      left: left ? v : 0,
      top: top ? v : 0,
      right: right ? v : 0,
      bottom: bottom ? v : 0,
    );
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    Sizes? horizontalPadding,
    Sizes? verticalPadding,
  }) {
    final h =
        horizontalPadding == null ? 0.0 : _value(context, horizontalPadding);
    final v = verticalPadding == null ? 0.0 : _value(context, verticalPadding);

    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }
}
