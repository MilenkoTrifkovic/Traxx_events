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
  final Widget child;
  final AuthController authController = Get.find<AuthController>();

  NavigationRailWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int selectedIndex;
    if (location.startsWith(AppRoute.hostEvents.path)) {
      selectedIndex = 0;
    } else if (location.startsWith(AppRoute.hostVenues.path)) {
      selectedIndex = 1;
    } else if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path)) {
      // both question sets and question detail pages are “Questions” tab
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
                  child: AppText.styledHeadingLarge(
                    context,
                    'X',
                    color: AppColors.white,
                  ),
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
            onDestinationSelected: (index) async {
              // ❌ DO NOT early return based on selectedIndex anymore
              // we want index 2 to always go back to the Question Sets page

              if (index == 0) {
                pushAndRemoveAllRoute(AppRoute.hostEvents, context);
              } else if (index == 1) {
                pushAndRemoveAllRoute(AppRoute.hostVenues, context);
              } else if (index == 2) {
                // Always go to the Question Sets page for the Questions tab
                pushAndRemoveAllRoute(AppRoute.hostQuestionSets, context);
              } else if (index == 3) {
                try {
                  await authController.logout();
                  if (context.mounted) {
                    pushAndRemoveAllRoute(AppRoute.welcome, context);
                  }
                } catch (e) {
                  print('Logout error: $e');
                  if (context.mounted) {
                    pushAndRemoveAllRoute(AppRoute.welcome, context);
                  }
                }
              }
            },
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.wine_bar_outlined),
                selectedIcon: const Icon(Icons.wine_bar),
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
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu),
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
                icon: const Icon(Icons.quiz_outlined),
                selectedIcon: const Icon(Icons.quiz),
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
                ),
                selectedIcon: const Icon(Icons.logout),
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
