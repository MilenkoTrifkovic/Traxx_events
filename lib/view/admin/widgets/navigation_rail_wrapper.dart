import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// A wrapper widget that adds a navigation rail to the left side of the screen.
///
/// This widget provides a vertical navigation bar with:
/// - Events list navigation
/// - Create event navigation
/// - Visual feedback for the current route
/// - Themed styling and icons
///
/// The navigation rail uses [GoRouter] for navigation and maintains the selected
/// state based on the current route.
class NavigationRailWrapper extends StatelessWidget {
  final Widget child;
  final AuthController authController = Get.find<AuthController>();

  NavigationRailWrapper({
    super.key,
    required this.child,
  });

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoute.hostEvents.path)) return 0;
    if (location.startsWith(AppRoute.calendarView.path)) return 1;
    if (location.startsWith(AppRoute.hostVenues.path)) return 2;
    if (location.startsWith(AppRoute.hostMenus.path)) return 3;

    // ✅ Questions: sets + questions + setQuestions route
    if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionSetQuestions.path)) {
      return 4;
    }

    // ✅ Users
    if (location.startsWith(AppRoute.hostRoleSelection.path)) return 5;

    // ✅ Settings
    if (location.startsWith(AppRoute.hostSettings.path)) return 6;

    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    switch (index) {
      case 0:
        pushAndRemoveAllRoute(AppRoute.hostEvents, context);
        return;
      case 1:
        pushAndRemoveAllRoute(AppRoute.calendarView, context);
        return;
      case 2:
        pushAndRemoveAllRoute(AppRoute.hostVenues, context);
        return;
      case 3:
        pushAndRemoveAllRoute(AppRoute.hostMenus, context);
        return;
      case 4:
        pushAndRemoveAllRoute(AppRoute.hostQuestionSets, context);
        return;
      case 5:
        pushAndRemoveAllRoute(AppRoute.hostRoleSelection, context);
        return;
      case 6:
        pushAndRemoveAllRoute(AppRoute.hostSettings, context);
        return;
      case 7:
        try {
          await authController.logout();
        } catch (_) {}
        if (context.mounted) {
          pushAndRemoveAllRoute(AppRoute.welcome, context);
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = _selectedIndexForLocation(location);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Sidebar
        Container(
          width: 220,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.black, width: 1.0),
          ),
          child: NavigationRail(
            backgroundColor: AppColors.primary,
            extended: true, // ✅ icon + text
            minWidth: 66,
            minExtendedWidth: 220,
            labelType: NavigationRailLabelType.none,

            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _onTap(context, i),

            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme:
                IconThemeData(color: Colors.white.withOpacity(0.9)),
            selectedLabelTextStyle: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600),
            unselectedLabelTextStyle:
                GoogleFonts.poppins(color: Colors.white.withOpacity(0.9)),

            indicatorColor: AppColors.primaryAccent,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),

            leading: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 10),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  AppText.styledHeadingLarge(
                    context,
                    'Traxx',
                    color: AppColors.white,
                  ),
                ],
              ),
            ),

            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.wine_bar_outlined),
                selectedIcon: Icon(Icons.wine_bar),
                label: Text('Events'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Calendar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_on_outlined),
                selectedIcon: Icon(Icons.location_on),
                label: Text('Venues'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('Menus'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: Text('Questions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout_outlined),
                selectedIcon: Icon(Icons.logout),
                label: Text('Logout'),
              ),
            ],
          ),
        ),

        const VerticalDivider(thickness: 1, width: 1),

        // ✅ Content padding fixes BOTH:
        // - gap between sidebar and heading
        // - gap between right edge and Add Event button
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
