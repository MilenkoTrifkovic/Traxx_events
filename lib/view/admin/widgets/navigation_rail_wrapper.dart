import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
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
  /// The main content to display beside the navigation rail.
  /// This will be expanded to fill the remaining space.
  final Widget child;
  final AuthController authController = Get.find<AuthController>();

  /// Creates a NavigationRailWrapper.
  ///
  /// Requires a [child] widget that will be displayed as the main content
  /// next to the navigation rail.
  NavigationRailWrapper({
    super.key,
    required this.child,
  });

  /// Builds the navigation rail layout
  ///
  /// The build process:
  /// 1. Determines the current route from GoRouter
  /// 2. Sets the selected index based on the current route
  /// 3. Creates a navigation rail with themed destinations
  /// 4. Displays the main content beside the rail
  @override
  Widget build(BuildContext context) {
    /// Get the current route path from GoRouter
    final String location = GoRouterState.of(context).uri.path;

    /// Determine which navigation item should be selected based on the current route
    int selectedIndex;
    if (location.startsWith(AppRoute.hostEvents.path)) {
      selectedIndex = 0;
    } else if (location.startsWith(AppRoute.hostVenues.path)) {
      selectedIndex = 1;
    } else if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path)) {
      selectedIndex = 2;
    } else {
      selectedIndex = 0;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 66.0,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.black,
              width: 1.0,
            ),
          ),
          child: NavigationRail(
            backgroundColor: AppColors.primary,
            leading: SizedBox(
              height: 64.0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 24.0,
                  child: AppText.styledHeadingLarge(context, 'X',
                      color: AppColors.white),
                ),
              ),
            ),

            selectedIconTheme: IconThemeData(color: AppColors.white),
            indicatorColor: AppColors.primaryAccent,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minWidth: 34.0,
            minExtendedWidth: 34.0,
            labelType: NavigationRailLabelType.none,
            extended: false,
            selectedIndex: selectedIndex,

            /// Handles navigation when a destination is selected
            ///
            /// - Prevents re-navigation to the current route
            /// - Uses different navigation strategies for different destinations:
            ///   * Events list: Clears navigation stack and pushes route
            ///   * Create event: Pushes route on top of current stack
            onDestinationSelected: (index) async {
              if (index == selectedIndex)
                return; // Prevents opening the same page
              if (index == 0) {
                pushAndRemoveAllRoute(AppRoute.hostEvents, context);
              } else if (index == 1) {
                // Navigate to menus
                pushAndRemoveAllRoute(AppRoute.hostVenues, context);
              } else if (index == 2) {
                // Navigate to questions
                pushAndRemoveAllRoute(AppRoute.hostQuestionSets, context);
              } else if (index == 3) {
                try {
                  // Properly await logout to ensure it completes
                  await authController.logout();
                  if (context.mounted) {
                    pushAndRemoveAllRoute(AppRoute.welcome, context);
                  }
                } catch (e) {
                  print('Logout error: $e');
                  // Navigate even if logout fails
                  if (context.mounted) {
                    pushAndRemoveAllRoute(AppRoute.welcome, context);
                  }
                }
              }
            },

            /// Navigation destinations configuration
            /// Each destination includes:
            /// - Regular and selected state icons
            /// - Themed labels with dynamic styling based on selection state
            /// - Color and weight changes to indicate active state
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.wine_bar_outlined), // unselected state
                selectedIcon: Icon(Icons.wine_bar), // selected state
                label: AppText.styledBodyMedium(
                  context,
                  'Events',
                  color: selectedIndex == 0
                      ? AppColors.primaryOld(context)
                      : AppColors.onPrimaryContainer(context),
                  weight:
                      selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined), // unselected state
                selectedIcon: Icon(Icons.restaurant_menu), // selected state
                label: AppText.styledBodyMedium(
                  context,
                  'Menus',
                  color: selectedIndex == 1
                      ? AppColors.primaryOld(context)
                      : AppColors.onPrimaryContainer(context),
                  weight:
                      selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined), // unselected state
                selectedIcon: Icon(Icons.quiz), // selected state
                label: AppText.styledBodyMedium(
                  context,
                  'Questions',
                  color: selectedIndex == 2
                      ? AppColors.primaryOld(context)
                      : AppColors.onPrimaryContainer(context),
                  weight:
                      selectedIndex == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.logout_outlined,
                  color: AppColors.white,
                ), // unselected state
                selectedIcon: Icon(Icons.logout), // selected state
                label: AppText.styledBodyMedium(
                  context,
                  'Logout',
                  color: selectedIndex == 3
                      ? AppColors.primaryOld(context)
                      : AppColors.onPrimaryContainer(context),
                  weight:
                      selectedIndex == 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: child),
      ],
    );
  }
}
