import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';

/// Pushes a new route onto the navigation stack.
///
/// Example:
/// ```dart
/// pushRoute(AppRoute.profile, context);
/// ```
/// Optionally, you can pass a value to replace a path parameter:
void pushRoute(AppRoute route, BuildContext context,
    {String? urlParam, Object? extra}) {
  String path = route.path;
  if (route.placeholder != null && urlParam != null) {
    print('Replacing placeholder ${route.placeholder} with value $urlParam');
    String placeholder =
        ':${route.placeholder!}'; //adds colon to match the path format
    path = path.replaceFirst(placeholder, urlParam);
  }
  print('Pushing route: $path');
  context.push(path, extra: extra);
}

/// Removes all existing routes and pushes a new route.
///
/// Example:
/// ```dart
/// pushAndRemoveAllRoute(AppRoute.login, context);
/// ```
///
// void pushAndRemoveAllRoute(AppRoute route, BuildContext context) {
//   context.go(route.path);
// }
void pushAndRemoveAllRoute(AppRoute route, BuildContext context,
    {String? urlParam, Object? extra}) {
  String path = route.path;
  if (route.placeholder != null && urlParam != null) {
    print('Replacing placeholder ${route.placeholder} with value $urlParam');
    String placeholder =
        ':${route.placeholder!}'; //adds colon to match the path format
    path = path.replaceFirst(placeholder, urlParam);
  }
  print('Pushing route: $path');
  context.go(path, extra: extra);
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
Future<void> popRoute(BuildContext context, [bool? result]) async {
  if (!context.mounted) return;

  if (context.canPop()) {
    context.pop(result);
  } else {
    context.go(AppRoute.welcome.path);
  }
}
