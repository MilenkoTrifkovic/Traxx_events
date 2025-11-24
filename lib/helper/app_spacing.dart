import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

class AppSpacing {
  /// Base spacing unit - xxxxs
  /// Example sizes: 2.0 on mobile, 4.0 on desktop
  static double xxxxs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 2.0 : 4.0;

  /// Base spacing unit - xxxs
  /// Example sizes: 4.0 on mobile, 8.0 on desktop
  static double xxxs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 4.0 : 8.0;

  /// Base spacing unit - xxs
  /// Example sizes: 6.0 on mobile, 12.0 on desktop
  static double xxs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 6.0 : 12.0;

  /// Base spacing unit - extra small
  /// Example sizes: 8.0 on mobile, 16.0 on desktop
  static double xs(BuildContext context) =>
      ScreenSize.isPhone(context) ? 8.0 : 16.0;

  /// Base spacing unit - small
  /// Example sizes: 12.0 on mobile, 24.0 on desktop
  static double sm(BuildContext context) =>
      ScreenSize.isPhone(context) ? 12.0 : 24.0;

  /// Base spacing unit - medium
  /// Example sizes: 16.0 on mobile, 32.0 on desktop
  static double md(BuildContext context) =>
      ScreenSize.isPhone(context) ? 16.0 : 32.0;

  /// Base spacing unit - large
  /// Example sizes: 20.0 on mobile, 40.0 on desktop
  static double lg(BuildContext context) =>
      ScreenSize.isPhone(context) ? 20.0 : 40.0;

  /// Base spacing unit - xl
  /// Example sizes: 24.0 on mobile, 48.0 on desktop
  static double xl(BuildContext context) =>
      ScreenSize.isPhone(context) ? 24.0 : 48.0;

  /// Base spacing unit - xxl
  /// Example sizes: 28.0 on mobile, 56.0 on desktop
  static double xxl(BuildContext context) =>
      ScreenSize.isPhone(context) ? 28.0 : 56.0;

  /// Base spacing unit - xxxl
  /// Example sizes: 32.0 on mobile, 64.0 on desktop
  static double xxxl(BuildContext context) =>
      ScreenSize.isPhone(context) ? 32.0 : 64.0;

  /// Base spacing unit - xxxxl
  /// Example sizes: 40.0 on mobile, 80.0 on desktop
  static double xxxxl(BuildContext context) =>
      ScreenSize.isPhone(context) ? 40.0 : 80.0;

  /// Base spacing unit - xxxxxl
  /// Example sizes: 56.0 on mobile, 112.0 on desktop
  static double xxxxxl(BuildContext context) =>
      ScreenSize.isPhone(context) ? 56.0 : 112.0;

  /// Responsive vertical spacer with xxxxs height
  static SizedBox verticalXxxxs(BuildContext context) =>
      SizedBox(height: xxxxs(context));

  /// Responsive vertical spacer with xxxs height
  static SizedBox verticalXxxs(BuildContext context) =>
      SizedBox(height: xxxs(context));

  /// Responsive vertical spacer with xxs height
  static SizedBox verticalXxs(BuildContext context) =>
      SizedBox(height: xxs(context));

  /// Responsive vertical spacer with extra small height
  /// Example sizes: height of 8.0 on mobile, 16.0 on desktop
  static SizedBox verticalXs(BuildContext context) =>
      SizedBox(height: xs(context));

  /// Responsive vertical spacer with small height
  static SizedBox verticalSm(BuildContext context) =>
      SizedBox(height: sm(context));

  /// Responsive vertical spacer with medium height
  /// Example sizes: height of 16.0 on mobile, 32.0 on desktop
  static SizedBox verticalMd(BuildContext context) =>
      SizedBox(height: md(context));

  /// Responsive vertical spacer with large height
  static SizedBox verticalLg(BuildContext context) =>
      SizedBox(height: lg(context));

  /// Responsive vertical spacer with xl height
  static SizedBox verticalXl(BuildContext context) =>
      SizedBox(height: xl(context));

  /// Responsive vertical spacer with xxl height
  static SizedBox verticalXxl(BuildContext context) =>
      SizedBox(height: xxl(context));

  /// Responsive vertical spacer with xxxl height
  static SizedBox verticalXxxl(BuildContext context) =>
      SizedBox(height: xxxl(context));

  /// Responsive vertical spacer with xxxxl height
  static SizedBox verticalXxxxl(BuildContext context) =>
      SizedBox(height: xxxxl(context));

  /// Responsive vertical spacer with xxxxxl height
  static SizedBox verticalXxxxxl(BuildContext context) =>
      SizedBox(height: xxxxxl(context));

  /// Responsive horizontal spacer with xxxxs width
  static SizedBox horizontalXxxxs(BuildContext context) =>
      SizedBox(width: xxxxs(context));

  /// Responsive horizontal spacer with xxxs width
  static SizedBox horizontalXxxs(BuildContext context) =>
      SizedBox(width: xxxs(context));

  /// Responsive horizontal spacer with xxs width
  static SizedBox horizontalXxs(BuildContext context) =>
      SizedBox(width: xxs(context));

  /// Responsive horizontal spacer with extra small width
  /// Example sizes: width of 8.0 on mobile, 16.0 on desktop
  static SizedBox horizontalXs(BuildContext context) =>
      SizedBox(width: xs(context));

  /// Responsive horizontal spacer with small width
  /// Example sizes: width of 12.0 on mobile, 24.0 on desktop
  static SizedBox horizontalSm(BuildContext context) =>
      SizedBox(width: sm(context));

  /// Responsive horizontal spacer with medium width
  /// Example sizes: width of 16.0 on mobile, 32.0 on desktop
  static SizedBox horizontalMd(BuildContext context) =>
      SizedBox(width: md(context));

  /// Responsive horizontal spacer with large width
  static SizedBox horizontalLg(BuildContext context) =>
      SizedBox(width: lg(context));

  /// Responsive horizontal spacer with xl width
  static SizedBox horizontalXl(BuildContext context) =>
      SizedBox(width: xl(context));

  /// Responsive horizontal spacer with xxl width
  static SizedBox horizontalXxl(BuildContext context) =>
      SizedBox(width: xxl(context));

  /// Responsive horizontal spacer with xxxl width
  static SizedBox horizontalXxxl(BuildContext context) =>
      SizedBox(width: xxxl(context));

  /// Responsive horizontal spacer with xxxxl width
  static SizedBox horizontalXxxxl(BuildContext context) =>
      SizedBox(width: xxxxl(context));

  /// Responsive horizontal spacer with xxxxxl width
  static SizedBox horizontalXxxxxl(BuildContext context) =>
      SizedBox(width: xxxxxl(context));
}
