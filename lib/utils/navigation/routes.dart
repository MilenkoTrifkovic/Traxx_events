import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';

/// Pushes a new route onto the navigation stack.
///
/// Example:
/// ```dart
/// pushRoute(AppRoute.profile, context);
/// ```
///
void pushRoute(AppRoute route, BuildContext context) {
  // TODO: make a centralized, type-safe navigation service with params, logging, and no BuildContext
  context.push(route.path);
}

/// Removes all existing routes and pushes a new route.
///
/// Example:
/// ```dart
/// pushAndRemoveAllRoute(AppRoute.login, context);
/// ```
///
void pushAndRemoveAllRoute(AppRoute route, BuildContext context) {
  context.go(route.path);
}

/// Replaces the current route with a new one.
///
/// Example:
/// ```dart
/// replaceRoute(AppRoute.dashboard, context);
/// ```
///
void replaceRoute(
  AppRoute route,
  BuildContext context,
) {
  context.replace(route.path);
}

/// Navigates back to the previous route if possible.
///
/// Example:
/// await popRoute(context);
///
/// Safely checks if the context is still mounted before popping.
Future<void> popRoute(BuildContext context) async {
  if (context.mounted) {
    context.pop();
  }
}
