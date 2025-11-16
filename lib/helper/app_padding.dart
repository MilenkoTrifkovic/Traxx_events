import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

abstract class AppPadding {
  static const Map<Sizes, double> mobileValues = {
    Sizes.xxxs: 2.0,
    Sizes.xxs: 4.0,
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

  static const Map<Sizes, double> desktopValues = {
    Sizes.xxxs: 4.0,
    Sizes.xxs: 8.0,
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

  static EdgeInsets all(BuildContext context, {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.all(value);
  }

  static EdgeInsets horizontal(BuildContext context,
      {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.symmetric(horizontal: value);
  }

  static EdgeInsets vertical(BuildContext context,
      {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.symmetric(vertical: value);
  }

  static EdgeInsets bottom(BuildContext context, {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.only(bottom: value);
  }

  static EdgeInsets top(BuildContext context, {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.only(top: value);
  }

  static EdgeInsets left(BuildContext context, {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.only(left: value);
  }

  static EdgeInsets right(BuildContext context, {required Sizes paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.only(right: value);
  }

  static EdgeInsets only(
    BuildContext context, {
    required Sizes paddingType,
    bool left = false,
    bool top = false,
    bool right = false,
    bool bottom = false,
  }) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.only(
      left: left ? value : 0,
      top: top ? value : 0,
      right: right ? value : 0,
      bottom: bottom ? value : 0,
    );
  }
}
