import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  /// The main content to display beside the navigation rail.
  /// This will be expanded to fill the remaining space.
  final Widget child;

  /// Creates a NavigationRailWrapper.
  ///
  /// Requires a [child] widget that will be displayed as the main content
  /// next to the navigation rail.
  const NavigationRailWrapper({
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
    if (location == '/host-events') {
      selectedIndex = 0; // Events list view
    } else if (location == '/host-create-event') {
      selectedIndex = 1; // Create event view
    } else {
      selectedIndex = 0; // Default to events list
    }
    return Row(
      children: [
        NavigationRail(
          backgroundColor: AppColors.primaryContainer(context),
          selectedIconTheme: IconThemeData(color: AppColors.primary(context)),
          labelType: NavigationRailLabelType.none,
          extended: true,
          selectedIndex: selectedIndex,

          /// Handles navigation when a destination is selected
          ///
          /// - Prevents re-navigation to the current route
          /// - Uses different navigation strategies for different destinations:
          ///   * Events list: Clears navigation stack and pushes route
          ///   * Create event: Pushes route on top of current stack
          onDestinationSelected: (index) {
            if (index == selectedIndex)
              return; // Prevents opening the same page
            if (index == 0) {
              pushAndRemoveAllRoute(AppRoute.hostEvents, context);
            } else if (index == 1) {
              pushRoute(AppRoute.hostCreateEvent, context);
            }
          },

          /// Navigation destinations configuration
          /// Each destination includes:
          /// - Regular and selected state icons
          /// - Themed labels with dynamic styling based on selection state
          /// - Color and weight changes to indicate active state
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.event_outlined), // unselected state
              selectedIcon: Icon(Icons.event), // selected state
              label: AppText.styledBodyMedium(
                context,
                'Events',
                color: selectedIndex == 0
                    ? AppColors.primary(context)
                    : AppColors.onPrimaryContainer(context),
                weight:
                    selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.add_circle_outline), // unselected state
              selectedIcon: Icon(Icons.add_circle), // selected state
              label: AppText.styledBodyMedium(
                context,
                'Create Event',
                color: selectedIndex == 1
                    ? AppColors.primary(context)
                    : AppColors.onPrimaryContainer(context),
                weight:
                    selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: child),
      ],
    );
  }
}
