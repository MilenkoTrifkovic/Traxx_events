import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/admin_user_management_header.dart';
import 'package:traxx_wepapp/layout/headers/calender_text_header.dart';
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
Widget getPageHeader(
  GoRouterState state, {
  GlobalKey<ScaffoldState>? drawerScaffoldKey,
}) {
  final location = state.matchedLocation;

  if (location == AppRoute.hostEvents.path) {
    return AppBarCustom(
      content: EventListHeader(),
      maxContentWidth: null,
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location.contains('/guest-preview')) {
    final eventId =
        state.pathParameters[AppRoute.guestSidePreview.placeholder] ??
            _extractEventIdFromPath(state.uri.toString());
    if (eventId != null) {
      return AppBarCustom(
        content: GuestSidePreviewHeader(eventId: eventId),
        drawerScaffoldKey: drawerScaffoldKey,
      );
    }
  }

  if (location.startsWith('/event-details/') &&
      !location.contains('/guest-preview')) {
    return AppBarCustom(
      content: HostEventDetailsHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location == AppRoute.calendarView.path) {
    return AppBarCustom(
      content: CalenderTextHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location == AppRoute.hostVenues.path) {
    return AppBarCustom(
      content: VenuesManagementHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location == AppRoute.hostMenus.path) {
    return AppBarCustom(
      content: MenusManagementHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location == AppRoute.hostRoleSelection.path) {
    return AppBarCustom(
      content: AdminUserManagementHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  // ✅ Questions routes — SAME AppBarCustom header as other pages
  if (location == AppRoute.hostQuestionSets.path ||
      location.startsWith('/host-question-sets/') ||
      location == AppRoute.hostQuestions.path ||
      location.startsWith(AppRoute.hostQuestionSetQuestions.path) ||
      location.startsWith(AppRoute.hostQuestionRules.path)) {
    return AppBarCustom(
      content: const QuestionsManagementHeader(),
      maxContentWidth: null, // ✅ ensures same feel as Events header
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  if (location == AppRoute.hostSettings.path) {
    return AppBarCustom(
      content: SettingsHeader(),
      drawerScaffoldKey: drawerScaffoldKey,
    );
  }

  return const SizedBox.shrink();
}

/// Extracts eventId from a path like /event-details/abc123/guest-preview
String? _extractEventIdFromPath(String path) {
  final regex = RegExp(r'/event-details/([^/]+)');
  final match = regex.firstMatch(path);
  return match?.group(1);
}
