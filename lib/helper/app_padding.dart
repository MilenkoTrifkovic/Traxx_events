import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

abstract class AppPadding {
  static const Map<Sizes, double> mobileValues = {
    Sizes.xs: 4.0,
    Sizes.sm: 8.0,
    Sizes.md: 16.0,
    Sizes.lg: 24.0,
    Sizes.xl: 32.0,
  };

  static const Map<Sizes, double> desktopValues = {
    Sizes.xs: 8.0,
    Sizes.sm: 12.0,
    Sizes.md: 20.0,
    Sizes.lg: 28.0,
    Sizes.xl: 36.0,
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
}
