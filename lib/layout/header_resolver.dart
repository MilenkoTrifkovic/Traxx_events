import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/admin_user_management_header.dart';
import 'package:traxx_wepapp/layout/headers/event_list_header.dart';
import 'package:traxx_wepapp/layout/headers/host_event_details_header.dart';
import 'package:traxx_wepapp/layout/headers/menus_management_header.dart';
import 'package:traxx_wepapp/layout/headers/venues_management_header.dart';
import 'package:traxx_wepapp/layout/headers/questions_management_header.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/widgets/app_bar_custom.dart';

Widget getPageHeader(GoRouterState state) {
  print('Matched location: ${state.matchedLocation}');
  if (state.matchedLocation == AppRoute.hostEvents.path) {
    return AppBarCustom(content: EventListHeader());
  }
  // if (state.matchedLocation == AppRoute.eventDetails.path) {
  if (state.matchedLocation.startsWith('/event-details/')) {
    return AppBarCustom(content: HostEventDetailsHeader());
  }
  if (state.matchedLocation == AppRoute.hostVenues.path) {
    return AppBarCustom(
        content: VenuesManagementHeader());
  }
  if (state.matchedLocation == AppRoute.hostMenus.path) {
    return AppBarCustom(
        content: MenusManagementHeader());
  }
  if (state.matchedLocation == AppRoute.hostRoleSelection.path) {
    return AppBarCustom(
        content: AdminUserManagementHeader());
  }
  if (state.matchedLocation == AppRoute.hostQuestionSets.path) {
    return AppBarCustom(content: QuestionsManagementHeader());
  }
  if (state.matchedLocation == AppRoute.hostQuestions.path) {
    return AppBarCustom(content: QuestionsManagementHeader());
  }

  return const SizedBox.shrink();
}
