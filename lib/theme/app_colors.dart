import 'package:flutter/material.dart';

class AppColors {
  static Color primary = Color(0xFF111827);
  static Color primaryAccent = Color(0xFF2563EB);
  static Color secondary = Color(0xFF374151);
  static Color borderSubtle = Color(0xFFEEF2F6);
  static Color textMuted = Color(0xFF9CA3AF);
  static Color white = Color(0xFFFFFFFF);
  static Color fofofo = Color(0xFFF0F0F0);
  static Color inputError = Color(0xFFE53935);
  static Color borderInput = Color(0xFFD0D0D0);
  static Color borderHover = Color(0xFFA0A0A0);

// old colors
  static Color seedColor = Color(0xFF003A70);

  static Color success = Color(0xFF4CAF50); // Yes Color

  static Color primaryOld(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color primaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;
  static Color onPrimaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;
  static Color secondaryOld(BuildContext context) =>
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
