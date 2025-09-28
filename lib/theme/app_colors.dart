import 'package:flutter/material.dart';

class AppColors {
  static Color seedColor = Color(0xFF003A70);

  static Color success = Color(0xFF4CAF50); // Yes Color

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color primaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;
  static Color onPrimaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color onSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondary;
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color onBackground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color shadow(BuildContext context) =>
      Theme.of(context).colorScheme.shadow;

  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  static Color onError(BuildContext context) =>
      Theme.of(context).colorScheme.onError;
}
