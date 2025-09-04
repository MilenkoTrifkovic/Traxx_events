import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

class AppSpacing {
  /// Base spacing unit - extra small
  /// Example sizes: 4.0 on mobile, 8.0 on desktop
  static double xs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 4.0 : 8.0;

  /// Base spacing unit - small
  /// Example sizes: 8.0 on mobile, 12.0 on desktop
  static double sm(BuildContext context) =>
      ScreenSize.isPhone(context) ? 8.0 : 12.0;

  /// Base spacing unit - medium
  /// Example sizes: 16.0 on mobile, 20.0 on desktop
  static double md(BuildContext context) =>
      ScreenSize.isPhone(context) ? 16.0 : 20.0;

  /// Responsive vertical spacer with extra small height
  /// Example sizes: height of 4.0 on mobile, 8.0 on desktop
  static SizedBox verticalXs(BuildContext context) =>
      SizedBox(height: xs(context));

  /// Responsive vertical spacer with medium height
  /// Example sizes: height of 16.0 on mobile, 20.0 on desktop
  static SizedBox verticalMd(BuildContext context) =>
      SizedBox(height: md(context));

  /// Responsive horizontal spacer with extra small width
  /// Example sizes: width of 4.0 on mobile, 8.0 on desktop
  static SizedBox horizontalXs(BuildContext context) =>
      SizedBox(width: xs(context));

  /// Responsive horizontal spacer with small width
  /// Example sizes: width of 8.0 on mobile, 12.0 on desktop
  static SizedBox horizontalSm(BuildContext context) =>
      SizedBox(width: sm(context));

  /// Responsive horizontal spacer with medium width
  /// Example sizes: width of 16.0 on mobile, 20.0 on desktop
  static SizedBox horizontalMd(BuildContext context) =>
      SizedBox(width: md(context));
}
