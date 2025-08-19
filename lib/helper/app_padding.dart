import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

enum PaddingType {
  xs,
  sm,
  md,
  lg,
  xl,
}

abstract class AppPadding {
  static const Map<PaddingType, double> mobileValues = {
    PaddingType.xs: 4.0,
    PaddingType.sm: 8.0,
    PaddingType.md: 16.0,
    PaddingType.lg: 24.0,
    PaddingType.xl: 32.0,
  };

  static const Map<PaddingType, double> desktopValues = {
    PaddingType.xs: 8.0,
    PaddingType.sm: 12.0,
    PaddingType.md: 20.0,
    PaddingType.lg: 28.0,
    PaddingType.xl: 36.0,
  };

  static EdgeInsets all(BuildContext context,
      {required PaddingType paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.all(value);
  }

  static EdgeInsets horizontal(BuildContext context,
      {required PaddingType paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.symmetric(horizontal: value);
  }

  static EdgeInsets vertical(BuildContext context,
      {required PaddingType paddingType}) {
    final value = ScreenSize.isPhone(context)
        ? mobileValues[paddingType]!
        : desktopValues[paddingType]!;
    return EdgeInsets.symmetric(vertical: value);
  }
}
