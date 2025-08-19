import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

class AppSpacing {
  // Base spacing units
  static double xs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 4.0 : 8.0;
  static double sm(BuildContext context) =>
      ScreenSize.isPhone(context) ? 8.0 : 12.0;
  static double md(BuildContext context) =>
      ScreenSize.isPhone(context) ? 16.0 : 20.0;

  /// Responsive vertical spacers
  static SizedBox verticalXs(BuildContext context) =>
      SizedBox(height: xs(context));
  static SizedBox verticalMd(BuildContext context) =>
      SizedBox(height: md(context));

  /// Responsive horizontal spacers
  static SizedBox horizontalXs(BuildContext context) =>
      SizedBox(width: xs(context));
}
