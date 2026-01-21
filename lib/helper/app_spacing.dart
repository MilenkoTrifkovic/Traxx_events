import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

/// Requires your existing `ScreenSize` class:
/// - ScreenSize.isPhone(context)
/// - ScreenSize.isTablet(context)
/// - ScreenSize.isDesktop(context)
///
/// This AppSpacing supports Phone / Tablet / Desktop and keeps your same API.
class AppSpacing {
  // ---- core resolver (phone/tablet/desktop) ----
  static double _v(
    BuildContext context, {
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    if (ScreenSize.isPhone(context)) return phone;
    if (ScreenSize.isTablet(context)) return tablet;
    return desktop;
  }

  // ---- spacing values ----

  /// Base spacing unit - xxxxs
  /// Example sizes: 2.0 on phone, 3.0 on tablet, 4.0 on desktop
  static double xxxxs(BuildContext context) =>
      _v(context, phone: 2.0, tablet: 3.0, desktop: 4.0);

  /// Base spacing unit - xxxs
  /// Example sizes: 4.0 on phone, 6.0 on tablet, 8.0 on desktop
  static double xxxs(BuildContext context) =>
      _v(context, phone: 4.0, tablet: 6.0, desktop: 8.0);

  /// Base spacing unit - xxs
  /// Example sizes: 6.0 on phone, 9.0 on tablet, 12.0 on desktop
  static double xxs(BuildContext context) =>
      _v(context, phone: 6.0, tablet: 9.0, desktop: 12.0);

  /// Base spacing unit - extra small
  /// Example sizes: 8.0 on phone, 12.0 on tablet, 16.0 on desktop
  static double xs(BuildContext context) =>
      _v(context, phone: 8.0, tablet: 12.0, desktop: 16.0);

  /// Base spacing unit - small
  /// Example sizes: 12.0 on phone, 18.0 on tablet, 24.0 on desktop
  static double sm(BuildContext context) =>
      _v(context, phone: 12.0, tablet: 18.0, desktop: 24.0);

  /// Base spacing unit - medium
  /// Example sizes: 16.0 on phone, 24.0 on tablet, 32.0 on desktop
  static double md(BuildContext context) =>
      _v(context, phone: 16.0, tablet: 24.0, desktop: 32.0);

  /// Base spacing unit - large
  /// Example sizes: 20.0 on phone, 30.0 on tablet, 40.0 on desktop
  static double lg(BuildContext context) =>
      _v(context, phone: 20.0, tablet: 30.0, desktop: 40.0);

  /// Base spacing unit - xl
  /// Example sizes: 24.0 on phone, 36.0 on tablet, 48.0 on desktop
  static double xl(BuildContext context) =>
      _v(context, phone: 24.0, tablet: 36.0, desktop: 48.0);

  /// Base spacing unit - xxl
  /// Example sizes: 28.0 on phone, 42.0 on tablet, 56.0 on desktop
  static double xxl(BuildContext context) =>
      _v(context, phone: 28.0, tablet: 42.0, desktop: 56.0);

  /// Base spacing unit - xxxl
  /// Example sizes: 32.0 on phone, 48.0 on tablet, 64.0 on desktop
  static double xxxl(BuildContext context) =>
      _v(context, phone: 32.0, tablet: 48.0, desktop: 64.0);

  /// Base spacing unit - xxxxl
  /// Example sizes: 40.0 on phone, 60.0 on tablet, 80.0 on desktop
  static double xxxxl(BuildContext context) =>
      _v(context, phone: 40.0, tablet: 60.0, desktop: 80.0);

  /// Base spacing unit - xxxxxl
  /// Example sizes: 56.0 on phone, 84.0 on tablet, 112.0 on desktop
  static double xxxxxl(BuildContext context) =>
      _v(context, phone: 56.0, tablet: 84.0, desktop: 112.0);

  // ---- vertical spacers ----

  static SizedBox verticalXxxxs(BuildContext context) =>
      SizedBox(height: xxxxs(context));
  static SizedBox verticalXxxs(BuildContext context) =>
      SizedBox(height: xxxs(context));
  static SizedBox verticalXxs(BuildContext context) =>
      SizedBox(height: xxs(context));
  static SizedBox verticalXs(BuildContext context) =>
      SizedBox(height: xs(context));
  static SizedBox verticalSm(BuildContext context) =>
      SizedBox(height: sm(context));
  static SizedBox verticalMd(BuildContext context) =>
      SizedBox(height: md(context));
  static SizedBox verticalLg(BuildContext context) =>
      SizedBox(height: lg(context));
  static SizedBox verticalXl(BuildContext context) =>
      SizedBox(height: xl(context));
  static SizedBox verticalXxl(BuildContext context) =>
      SizedBox(height: xxl(context));
  static SizedBox verticalXxxl(BuildContext context) =>
      SizedBox(height: xxxl(context));
  static SizedBox verticalXxxxl(BuildContext context) =>
      SizedBox(height: xxxxl(context));
  static SizedBox verticalXxxxxl(BuildContext context) =>
      SizedBox(height: xxxxxl(context));

  // ---- horizontal spacers ----

  static SizedBox horizontalXxxxs(BuildContext context) =>
      SizedBox(width: xxxxs(context));
  static SizedBox horizontalXxxs(BuildContext context) =>
      SizedBox(width: xxxs(context));
  static SizedBox horizontalXxs(BuildContext context) =>
      SizedBox(width: xxs(context));
  static SizedBox horizontalXs(BuildContext context) =>
      SizedBox(width: xs(context));
  static SizedBox horizontalSm(BuildContext context) =>
      SizedBox(width: sm(context));
  static SizedBox horizontalMd(BuildContext context) =>
      SizedBox(width: md(context));
  static SizedBox horizontalLg(BuildContext context) =>
      SizedBox(width: lg(context));
  static SizedBox horizontalXl(BuildContext context) =>
      SizedBox(width: xl(context));
  static SizedBox horizontalXxl(BuildContext context) =>
      SizedBox(width: xxl(context));
  static SizedBox horizontalXxxl(BuildContext context) =>
      SizedBox(width: xxxl(context));
  static SizedBox horizontalXxxxl(BuildContext context) =>
      SizedBox(width: xxxxl(context));
  static SizedBox horizontalXxxxxl(BuildContext context) =>
      SizedBox(width: xxxxxl(context));
}
