import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/admin_user_management_header.dart';
import 'package:traxx_wepapp/layout/headers/calendar_header.dart';
import 'package:traxx_wepapp/layout/headers/event_list_header.dart';
import 'package:traxx_wepapp/layout/headers/host_event_details_header.dart';
import 'package:traxx_wepapp/layout/headers/guest_side_preview_header.dart';
import 'package:traxx_wepapp/layout/headers/menus_management_header.dart';
import 'package:traxx_wepapp/layout/headers/settings_header.dart';
import 'package:traxx_wepapp/layout/headers/venues_management_header.dart';
import 'package:traxx_wepapp/layout/headers/questions_management_header.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/widgets/app_bar_custom.dart';

/// Returns the header widget for a given route state.
/// 
/// Uses [GoRouterState.of(context)] to get the current location for accurate
/// header resolution, especially when navigating within shell routes.
Widget getPageHeader(GoRouterState state, {BuildContext? context}) {
  // Use context-based state if available for more accurate location
  final location = context != null 
      ? GoRouterState.of(context).uri.toString()
      : state.matchedLocation;
  
  print('Header resolver - location: $location');
  
  if (location == AppRoute.hostEvents.path) {
    return AppBarCustom(content: EventListHeader());
  }
  
  // Check for guest preview page first (before event details check)
  if (location.contains('/guest-preview')) {
    print('GUEST preview page found');
    final eventId = state.pathParameters[AppRoute.guestSidePreview.placeholder] 
        ?? _extractEventIdFromPath(location);
    if (eventId != null) {
      return AppBarCustom(content: GuestSidePreviewHeader(eventId: eventId));
    }
  }
  
  // Check for event details page
  if (location.startsWith('/event-details/') && !location.contains('/guest-preview')) {
    return AppBarCustom(content: HostEventDetailsHeader());
  }
  if (location == AppRoute.calendarView.path) {
    return AppBarCustom(content: CalendarHeader());
  }
  if (location == AppRoute.hostVenues.path) {
    return AppBarCustom(content: VenuesManagementHeader());
  }
  if (location == AppRoute.hostMenus.path) {
    return AppBarCustom(content: MenusManagementHeader());
  }
  if (location == AppRoute.hostRoleSelection.path) {
    return AppBarCustom(content: AdminUserManagementHeader());
  }
  if (location == AppRoute.hostQuestionSets.path ||
      location.startsWith('/host-question-sets/') ||
      location == AppRoute.hostQuestions.path) {
    return AppBarCustom(content: QuestionsManagementHeader());
  }

  if (location == AppRoute.hostQuestions.path) {
    return AppBarCustom(content: QuestionsManagementHeader());
  }

  if (location == AppRoute.hostSettings.path) {
    return AppBarCustom(content: SettingsHeader());
  }

  return const SizedBox.shrink();
}

/// Extracts eventId from a path like /event-details/abc123/guest-preview
String? _extractEventIdFromPath(String path) {
  final regex = RegExp(r'/event-details/([^/]+)');
  final match = regex.firstMatch(path);
  return match?.group(1);
}
