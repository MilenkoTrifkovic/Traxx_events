import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/custom_error_page.dart';
import 'package:traxx_wepapp/view/host/create_event/create_event_view.dart';
import 'package:traxx_wepapp/view/host/host_event_list_screen.dart';
import 'package:traxx_wepapp/view/host/widgets/navigation_rail_wrapper.dart';
import 'package:traxx_wepapp/view/info/about_view.dart';
import 'package:traxx_wepapp/view/info/contact_view.dart';
import 'package:traxx_wepapp/view/info/welcome_view.dart';
import 'package:traxx_wepapp/widgets/app_scaffold.dart';

/// Router setup for the Traxx application.
/// Currently implementing basic navigation structure with go_router.
///

/// Key for the host section's nested navigation
final GlobalKey<NavigatorState> hostNavigatorKey = GlobalKey<NavigatorState>();

///
/// Structure:
/// - Public routes (welcome, about, contact)
/// - Host section with nested navigation
GoRouter buildRouter() {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoute.welcome.path,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.welcome.path,
        builder: (context, state) => WelcomeView(),
      ),
      GoRoute(
        path: AppRoute.aboutView.path,
        builder: (context, state) => AboutView(),
      ),
      GoRoute(
        path: AppRoute.contactView.path,
        builder: (context, state) => ContactView(),
      ),
      //HOST SHELL ROUTE
      ShellRoute(
        navigatorKey: hostNavigatorKey,
        builder: (context, state, child) {
          final hostController = Get.find<HostController>();
          final authController = Get.find<AuthController>();
          return Obx(() {
            try {
              if (hostController.isLoading.value ||
                  authController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              final name = authController.userName.value;
              return AppScaffold(
                body: NavigationRailWrapper(child: child),
                role: 'host',
                name: name,
                onLogout: authController.logout,
              );
            } catch (e) {
              return Container(); //Temporary
              // Error Handling or redirection
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.hostEvents.path,
            builder: (context, state) =>
                HostEventListScreen(), //Not created yet
          ),
          GoRoute(
            path: AppRoute.hostCreateEvent.path,
            builder: (context, state) => CreateEventView(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CustomErrorPage(),
  );
}
