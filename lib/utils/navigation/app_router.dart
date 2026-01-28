import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/payment_history_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/users_and_roles_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/controller/menus_list_controller.dart';
import 'package:traxx_wepapp/controller/menus_screen_controller.dart';
import 'package:traxx_wepapp/features/common/calendar_page/view/calendar_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/compaignons_info_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/guest_count_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/guest_thank_you_page.dart';
import 'package:traxx_wepapp/features/settings/view/settings_page.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/view/buy_credits_page.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/view/payment_success_page.dart';
import 'package:traxx_wepapp/features/admin/buy_credits/view/payment_cancelled_page.dart';
import 'package:traxx_wepapp/helper/fetch_event.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/layout/header_resolver.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/custom_error_page.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';
import 'package:traxx_wepapp/view/admin/event_details/demographic_response_page.dart';
import 'package:traxx_wepapp/view/admin/event_details/menu_response_page.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/rsvp_response_page.dart';
import 'package:traxx_wepapp/view/admin/questions/host_questions_rules_screen.dart';
import 'package:traxx_wepapp/view/admin/questions/host_questions_sets_screen.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/menus_details_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/menus_view.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/view/admin_user_list_page.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar.dart';
import 'package:traxx_wepapp/view/admin/widgets/sidebar_nav_tiles.dart';
import 'package:traxx_wepapp/view/authentication/login/email_verification_view.dart';
import 'package:traxx_wepapp/view/guest/guest_event_details.dart';
import 'package:traxx_wepapp/view/guest/respond/respond_screen.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_edit_event_view.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/guests_section/set_guests._view.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/menu_section/set_menus_view.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/questions_section/set_questions_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/venues_view.dart';
import 'package:traxx_wepapp/view/admin/questions/host_questions_screen.dart';
import 'package:traxx_wepapp/view/common/event_list_screen.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/responses_section.dart/responses_view.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/organisation_info_popup_view.dart';
import 'package:traxx_wepapp/view/admin/widgets/navigation_rail_wrapper.dart';
import 'package:traxx_wepapp/view/authentication/login/welcome_view.dart';
import 'package:traxx_wepapp/widgets/content_wrapper.dart';
import 'package:traxx_wepapp/widgets/event_loader.dart';
import 'package:traxx_wepapp/layout/guest_layout/guest_page_wrapper.dart';
import 'package:traxx_wepapp/view/admin/event_details/event_demographic_analyzer_page.dart';
import 'package:traxx_wepapp/view/admin/event_details/event_menu_analyzer_page.dart';
import 'package:traxx_wepapp/features/admin/admin_guest_side_preview/view/guest_side_preview_page.dart';
import 'package:traxx_wepapp/utils/web_reload_stub.dart'
    if (dart.library.html) 'package:traxx_wepapp/utils/web_reload_web.dart';

/// Router setup for the Traxx application.
/// Currently implementing basic navigation structure with go_router.
///

/// Key for the host section's nested navigation
final GlobalKey<NavigatorState> hostNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> guestNavigationKey =
    GlobalKey<NavigatorState>();
const double kNavCollapseWidth = 900; // when to switch sidebar -> drawer
final GlobalKey<ScaffoldState> hostShellScaffoldKey =
    GlobalKey<ScaffoldState>();

///
/// Structure:
/// - Public routes (welcome, about, contact)
/// - Host section with nested navigation
GoRouter buildRouter() {
  final eventController = Get.find<EventController>();
  final authController = Get.find<AuthController>();
  Widget _spinner() {
    // Keep it visually stable (no layout jumps)
    return const Scaffold(
      body: Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }

  Widget realShell({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    required EventListController eventListController,
    required String orgId,
  }) {
    final location = state.matchedLocation;

    final isQuestionsPage =
        location.startsWith(AppRoute.hostQuestionSets.path) ||
            location.startsWith(AppRoute.hostQuestions.path) ||
            location.startsWith(AppRoute.hostQuestionSetQuestions.path) ||
            location.startsWith(AppRoute.hostQuestionRules.path);

    const Color gfBackground = Color(0xFFF4F0FB);
    final contentColor = isQuestionsPage
        ? gfBackground
        : const Color.fromARGB(255, 247, 247, 247);

    return OrgDataBootstrap(
      orgId: orgId,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < kNavCollapseWidth;

          final header = getPageHeader(
            state,
            drawerScaffoldKey: isMobile ? hostShellScaffoldKey : null,
          );

          final page = ContentWrapper(
            contentColor: contentColor,
            header: header,
            child: child,
          );

          final shell = isMobile
              ? Scaffold(
                  key: hostShellScaffoldKey,
                  drawer: Drawer(
                    child:
                        HostDrawerMenuSidebar(location: state.matchedLocation),
                  ),
                  body: page,
                )
              : NavigationRailWrapper(child: page);

          return Stack(
            children: [
              shell,

              // ✅ Overlay loader instead of replacing the whole UI
              Obx(() {
                if (!eventListController.isLoading.value) {
                  return const SizedBox.shrink();
                }
                return const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  return GoRouter(
    refreshListenable:
        GoRouterRefreshStream(authController.routerRefresh.stream),
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, __) => AppRoute.welcome.path),

      GoRoute(
        path: AppRoute.welcome.path,
        redirect: (context, state) {
          // wait until auth/profile is known
          if (authController.isLoading.value) return null;

          if (!authController.isAuthenticated) return null;

          // signed in but needs email verify
          if (!authController.isAuthenticatedAndVerified) {
            return AppRoute.emailVerification.path;
          }

          // signed in but needs org
          if (!authController.companyInfoExists) {
            return AppRoute.hostOrganisationInfoForm.path;
          }

          // all good
          return AppRoute.hostEvents.path;
        },
        builder: (context, state) => const WelcomeView(),
      ),

      GoRoute(
        redirect: (context, state) {
          if (authController.isAuthenticatedAndVerified) {
            return AppRoute.hostEvents.path;
          }
          return null;
        },
        path: AppRoute.emailVerification.path,
        builder: (context, state) => EmailVerificationView(),
      ),
      GoRoute(
        redirect: (context, state) {
          if (authController.isLoading.value) return null;
          if (!authController.isAuthenticated) {
            return AppRoute.welcome.path;
          }
          if (!authController.isAuthenticatedAndVerified) {
            // Must verify email first
            return AppRoute.emailVerification.path;
          }
          if (authController.companyInfoExists) {
            // Org already exists → go straight to host events
            return AppRoute.hostEvents.path;
          }
          // Otherwise show the organisation form
          return null;
        },
        path: AppRoute.hostOrganisationInfoForm.path,
        builder: (context, state) => const OrganisationInfoPopupView(),
      ),

      GoRoute(
        path: AppRoute.thankYou.path,
        builder: (context, state) {
          final invId =
              (state.uri.queryParameters['invitationId'] ?? '').trim();
          final token = (state.uri.queryParameters['token'] ?? '').trim();
          return GuestThankYouPage(invitationId: invId, token: token);
        },
      ),

      // GUEST RESPONSE SHELL ROUTE
      // Public routes for guests responding to invitations (RSVP → Demographics → Menu → Thank You)
      ShellRoute(
        builder: (context, state, child) {
          final invitationId = state.uri.queryParameters['invitationId'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';

          final rsvpCtrl = Get.put(RsvpResponseController(), tag: invitationId);
          rsvpCtrl.invitationId = invitationId;
          rsvpCtrl.token = token;

          // Always ensure load at least once
          if (rsvpCtrl.invitationStatus.value == null &&
              !rsvpCtrl.isLoading.value) {
            rsvpCtrl.checkExistingResponse();
          }

          // ✅ CREATE GuestLayoutController HERE (not later)
          final guestLayout =
              Get.put(GuestLayoutController(), tag: invitationId);

          // start loading event immediately
          guestLayout.loadEventCoverImageFromInvitation(invitationId);

          return GuestPageWrapper(
            invitationId: invitationId,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoute.guestResponse.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];

              final forceDetails =
                  (state.uri.queryParameters['view'] ?? '') == 'details';

              return RsvpResponsePage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
                forceDetails: forceDetails, // ✅ NEW
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestCompanionsInfo.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];
              return CompaignonsInfoPage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestCompanions.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              final eventName = state.uri.queryParameters['eventName'];
              return GuestCountPage(
                invitationId: invitationId,
                token: token,
                eventName: eventName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.demographics.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';

              // Parse companion index if provided
              final companionIndexStr =
                  state.uri.queryParameters['companionIndex'];
              final int? companionIndex = companionIndexStr != null
                  ? int.tryParse(companionIndexStr)
                  : null;

              // Get companion name if provided
              final companionName = state.uri.queryParameters['companionName'];

              return DemographicResponsePage(
                invitationId: invitationId,
                token: token,
                embedded: false,
                showInvitationInput: false,
                companionIndex: companionIndex,
                companionName: companionName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.menuSelection.path,
            builder: (context, state) {
              final invitationId =
                  state.uri.queryParameters['invitationId'] ?? '';

              // Parse companion index if provided
              final companionIndexStr =
                  state.uri.queryParameters['companionIndex'];
              final int? companionIndex = companionIndexStr != null
                  ? int.tryParse(companionIndexStr)
                  : null;

              // Get companion name if provided
              final companionName = state.uri.queryParameters['companionName'];

              return GuestMenuSelectionPage(
                invitationId: invitationId,
                companionIndex: companionIndex,
                companionName: companionName,
              );
            },
          ),
          GoRoute(
            path: AppRoute.thankYou.path,
            redirect: (context, state) {
              final invitationId =
                  (state.uri.queryParameters['invitationId'] ?? '').trim();
              final token = (state.uri.queryParameters['token'] ?? '').trim();
              final eventName = state.uri.queryParameters['eventName'];

              // If invitationId is missing, just go to guest-response base route
              if (invitationId.isEmpty) {
                return AppRoute.guestResponse.path;
              }

              return Uri(
                path: AppRoute.guestResponse.path,
                queryParameters: {
                  'invitationId': invitationId,
                  if (token.isNotEmpty) 'token': token,
                  if (eventName != null && eventName.trim().isNotEmpty)
                    'eventName': eventName.trim(),
                },
              ).toString();
            },
          ),
        ],
      ),

      //HOST SHELL ROUTE
      ShellRoute(
        redirect: (context, state) {
          if (authController.isLoading.value) return null;
          if (!authController.isAuthenticated) return AppRoute.welcome.path;
          if (!authController.isAuthenticatedAndVerified)
            return AppRoute.emailVerification.path;
          if (!authController.companyInfoExists)
            return AppRoute.hostOrganisationInfoForm.path;
          return null;
        },
        navigatorKey: hostNavigatorKey,
        builder: (context, state, child) {
          final authCtrl = Get.find<AuthController>();
          final eventListController = Get.find<EventListController>();

          return Obx(() {
            if (authCtrl.isLoading.value) return _spinner();
            if (!authCtrl.isAuthenticated) return _spinner();

            final orgId = (authCtrl.organisationId ?? '').trim();
            if (orgId.isEmpty) return _spinner();

            // Ensure controllers exist (safe)
            if (!Get.isRegistered<VenuesController>())
              Get.put(VenuesController());
            if (!Get.isRegistered<MenusListController>())
              Get.put(MenusListController());
            if (!Get.isRegistered<MenusScreenController>())
              Get.put(MenusScreenController());
            if (!Get.isRegistered<EventsController>())
              Get.put(EventsController());
            if (!Get.isRegistered<OrganisationController>()) {
              Get.put(OrganisationController(orgId));
            }
            if (!Get.isRegistered<PaymentHistoryController>())
              Get.put(PaymentHistoryController());
            if (!Get.isRegistered<UsersAndRolesController>())
              Get.put(UsersAndRolesController());

            return realShell(
              context: context,
              state: state,
              child: child,
              eventListController: eventListController,
              orgId: orgId,
            );
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.hostEvents.path,
            builder: (context, state) => EventListScreen(),
          ),
          GoRoute(
            path: AppRoute.calendarView.path,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: AppRoute.hostMenus.path,
            builder: (context, state) => MenusView(),
          ),
          GoRoute(
            path: AppRoute.hostMenuDetails.path,
            builder: (context, state) {
              final menuId =
                  state.pathParameters[AppRoute.hostMenuDetails.placeholder]!;
              return MenuSetDetailsView(menuId: menuId);
            },
          ),
          GoRoute(
            path: AppRoute.hostVenues.path,
            builder: (context, state) => const VenuesView(),
          ),
          GoRoute(
            path: AppRoute.hostVenueDetails.path,
            builder: (context, state) {
              final venueId =
                  state.pathParameters[AppRoute.hostVenueDetails.placeholder]!;
              return VenuesView();
            },
          ),
          GoRoute(
            path: AppRoute.hostRoleSelection.path,
            builder: (context, state) {
              return AdminUserListPage();
            },
          ),
          GoRoute(
            path: AppRoute.hostQuestionSets.path,
            builder: (context, state) => const QuestionSetsScreen(),
          ),
          GoRoute(
            path: AppRoute.hostQuestions.path,
            builder: (context, state) {
              final setId = state.uri.queryParameters['setId'] ?? '';
              final setTitle = state.uri.queryParameters['setTitle'] ?? '';
              final setDescription =
                  state.uri.queryParameters['setDescription'] ?? '';

              if (setId.isEmpty) {
                return const QuestionSetsScreen();
              }

              return HostQuestionsScreen(
                questionSetId: setId,
              );
            },
          ),
          GoRoute(
            path: AppRoute.hostQuestionRules.path,
            builder: (context, state) => const QuestionRulesScreen(),
          ),

          GoRoute(
            path: AppRoute.hostQuestionSetQuestions.path,
            builder: (context, state) {
              final setId = state.pathParameters[
                  AppRoute.hostQuestionSetQuestions.placeholder]!;
              final setTitle = state.uri.queryParameters['setTitle'] ?? '';
              final setDescription =
                  state.uri.queryParameters['setDescription'] ?? '';
              return HostQuestionsScreen(
                questionSetId: setId,
              );
            },
          ),

          GoRoute(
            path: AppRoute.hostCreateEvent.path,
            builder: (context, state) => CreateEditEventView(),
          ),
          GoRoute(
            path: AppRoute.eventDetails.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              return AdminEventDetails(
                eventId: eventId,
              );
            },
          ),
          GoRoute(
            path: AppRoute.hostSettings.path,
            builder: (context, state) => SettingsPage(),
          ),
          GoRoute(
            path: AppRoute.hostBuyCredits.path,
            builder: (context, state) => BuyCreditsPage(),
          ),
          GoRoute(
            path: 'payment-success',
            builder: (context, state) => const PaymentSuccessPage(),
          ),
          GoRoute(
            path: 'payment-cancelled',
            builder: (context, state) => const PaymentCancelledPage(),
          ),
          GoRoute(
            path: AppRoute.eventQuestions.path,
            builder: (context, state) => SetQuestionsView(),
          ),
          GoRoute(
            path: AppRoute.eventMenus.path,
            builder: (context, state) {
              final Event? selectedEvent = eventController.selectedEvent.value;
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              if (selectedEvent != null) {
                return SetMenusView();
              }

              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  eventController.setSelectedEvent(snapshot.data!);

                  return SetMenusView();
                },
              );
            },
          ),
          GoRoute(
            path: AppRoute.eventDemographicAnalyzer.path,
            builder: (context, state) {
              final eventId = state.pathParameters[
                  AppRoute.eventDemographicAnalyzer.placeholder]!;
              return EventDemographicAnalyzerPage(eventId: eventId);
            },
          ),
          GoRoute(
            path: AppRoute.eventMenuAnalyzer.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventMenuAnalyzer.placeholder]!;
              return EventMenuAnalyzerPage(eventId: eventId);
            },
          ),
          GoRoute(
            path: AppRoute.guestSidePreview.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.guestSidePreview.placeholder]!;
              return GuestSidePreviewPage(eventId: eventId);
            },
          ),

          GoRoute(
            path: AppRoute.eventGuests.path,
            builder: (context, state) => SetGuestsView(),
          ),
          GoRoute(
            path: AppRoute.eventResponses.path,
            builder: (context, state) {
              String eventId =
                  state.pathParameters[AppRoute.eventResponses.placeholder]!;
              return EventLoader(
                eventController: eventController,
                eventId: eventId,
                builder: (context, event) => ResponsesView(),
              );
            },
          ),
          // GoRoute(
          //   path: AppRoute.hostDemographics.path,
          //   builder: (context, state) {
          //     final invitationId =
          //         state.uri.queryParameters['invitationId'] ?? '';
          //     return DemographicResponsePage(
          //       invitationId: invitationId,
          //       showInvitationInput: true,
          //       embedded: true, // ✅ NEW
          //     );
          //   },
          // ),
        ],
      ),
      // Guest Shell Route
      ShellRoute(
        navigatorKey: guestNavigationKey,
        builder: (context, state, child) {
          final authCtrl = Get.find<AuthController>();
          final eventListController = Get.find<EventListController>();

          return Obx(() {
            if (authCtrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final orgId = (authCtrl.organisationId ?? '').trim();
            if (orgId.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!Get.isRegistered<VenuesController>())
              Get.put(VenuesController());
            if (!Get.isRegistered<OrganisationController>())
              Get.put(OrganisationController(orgId));

            if (eventListController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return OrgDataBootstrap(
              orgId: orgId,
              child: Obx(() {
                if (eventListController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return NavigationRailWrapper(
                  child: ContentWrapper(
                    contentColor: const Color.fromARGB(255, 247, 247, 247),
                    header: getPageHeader(state),
                    child: child,
                  ),
                );
              }),
            );
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.guestEvents.path,
            builder: (context, state) => EventListScreen(),
          ),
          GoRoute(
            path: AppRoute.guestEventDetails.path,
            builder: (context, state) {
              final Event? event = eventController.selectedEvent.value;
              if (event != null) {
                return GuestEventDetails();
              }

              final eventId =
                  state.pathParameters[AppRoute.guestEventDetails.placeholder]!;
              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  eventController.setSelectedEvent(snapshot.data!);

                  return GuestEventDetails();
                },
              );
            },
          ),
          GoRoute(
            path: AppRoute.guestEventRespond.path,
            builder: (context, state) {
              final eventId =
                  state.pathParameters[AppRoute.eventDetails.placeholder]!;
              final Event? selectedEvent = eventController.selectedEvent.value;
              if (selectedEvent != null) {
                return RespondScreen(event: selectedEvent);
              }
              // final Event? event;
              // if (state.extra != null && state.extra is Event) {
              //   event = state.extra as Event;
              // } else {
              //   event = null;
              // }
              // final eventId =
              //     state.pathParameters[AppRoute.guestEventRespond.placeholder]!;
              //     Event event = EventFetcher()
              // return RespondScreen(eventId: eventId);
              return FutureBuilder<Event>(
                future: EventFetcher.fetchEvent(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return RespondScreen(event: snapshot.data!);
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CustomErrorPage(),
  );
}

class HostDrawerMenuSidebar extends StatelessWidget {
  final String location;
  const HostDrawerMenuSidebar({super.key, required this.location});

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoute.hostEvents.path)) return 0;
    if (location.startsWith(AppRoute.calendarView.path)) return 1;
    if (location.startsWith(AppRoute.hostVenues.path)) return 2;
    if (location.startsWith(AppRoute.hostMenus.path)) return 3;
    if (location.startsWith(AppRoute.hostQuestionSets.path) ||
        location.startsWith(AppRoute.hostQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionSetQuestions.path) ||
        location.startsWith(AppRoute.hostQuestionRules.path)) {
      return 4;
    }
    if (location.startsWith(AppRoute.hostRoleSelection.path)) return 5;
    if (location.startsWith(AppRoute.hostSettings.path)) return 6;
    return 0;
  }

  Future<void> _onTapFromDrawer(BuildContext drawerCtx, int index) async {
    // ✅ close drawer first
    Navigator.of(drawerCtx).pop();

    // ✅ choose where to navigate
    AppRoute? route;
    switch (index) {
      case 0:
        route = AppRoute.hostEvents;
        break;
      case 1:
        route = AppRoute.calendarView;
        break;
      case 2:
        route = AppRoute.hostVenues;
        break;
      case 3:
        route = AppRoute.hostMenus;
        break;
      case 4:
        route = AppRoute.hostQuestionSets;
        break;
      case 5:
        route = AppRoute.hostRoleSelection;
        break;
      case 6:
        route = AppRoute.hostSettings;
        break;
      case 7:
        try {
          await Get.find<AuthController>().logout();
        } catch (_) {}

        if (kIsWeb) {
          hardReload(); // ✅ wipes old GetX controllers completely
          return;
        }

        final navCtx = hostNavigatorKey.currentContext ??
            hostShellScaffoldKey.currentContext;

        if (navCtx != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            pushAndRemoveAllRoute(AppRoute.welcome, navCtx);
          });
        }
        return;
    }

    final navCtx =
        hostNavigatorKey.currentContext ?? hostShellScaffoldKey.currentContext;
    if (navCtx == null || route == null) return;

    // ✅ navigate AFTER drawer closes (prevents deactivated ancestor errors)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pushAndRemoveAllRoute(route!, navCtx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexForLocation(location);

    // Same items as your sidebar
    final items = <NavItemData>[
      const NavItemData(
        label: 'Events',
        icon: Icons.wine_bar_outlined,
        selectedIcon: Icons.wine_bar,
      ),
      const NavItemData(
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
      ),
      const NavItemData(
        label: 'Venues',
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on,
      ),
      const NavItemData(
        label: 'Menus',
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu,
      ),
      const NavItemData(
        label: 'Questions',
        icon: Icons.quiz_outlined,
        selectedIcon: Icons.quiz,
      ),
      const NavItemData(
        label: 'Users',
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
      ),
      const NavItemData(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      const NavItemData(
        label: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
      ),
    ];

    final organisationName = Get.isRegistered<OrganisationController>()
        ? Get.find<OrganisationController>().getOrganisationName()
        : 'Trax Events';

    final organisationPhotoUrl = Get.isRegistered<OrganisationController>()
        ? Get.find<OrganisationController>().getOrganisationPhotoUrl()
        : null;

    // ✅ CRITICAL:
    // Disable tooltips/hover effects inside Drawer to avoid "multiple tickers"
    // and pointer hover issues on web.
    return TooltipVisibility(
      visible: false,
      child: MouseRegion(
        opaque: true,
        onHover: (_) {}, // no-op to prevent hover-triggered rebuilds
        child: Sidebar(
          selectedIndex: selectedIndex,
          items: items,
          onTap: (i) => _onTapFromDrawer(context, i),

          // Drawer should be expanded always (same look)
          isExpanded: true,

          organisationName: organisationName,
          organisationPhotoUrl: organisationPhotoUrl,

          // Drawer doesn't need collapse toggle, keep no-op
          onToggleExpand: () {},
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class OrgDataBootstrap extends StatefulWidget {
  final String orgId;
  final Widget child;

  const OrgDataBootstrap({
    super.key,
    required this.orgId,
    required this.child,
  });

  @override
  State<OrgDataBootstrap> createState() => _OrgDataBootstrapState();
}

class _OrgDataBootstrapState extends State<OrgDataBootstrap> {
  String? _lastOrgId;

  void _kickoff() {
    if (_lastOrgId == widget.orgId) return;
    _lastOrgId = widget.orgId;

    Future.microtask(() {
      if (!mounted) return;
      Get.find<EventListController>().ensureLoaded(widget.orgId);
      Get.find<VenuesController>().ensureLoaded(widget.orgId);
    });
  }

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  @override
  void didUpdateWidget(covariant OrgDataBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orgId != widget.orgId) _kickoff();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
