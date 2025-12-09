import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/menus_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/users_and_roles_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/fetch_event.dart';
import 'package:traxx_wepapp/layout/header_resolver.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/custom_error_page.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';
import 'package:traxx_wepapp/view/admin/questions/host_questions_sets_screen.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/menus_view.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/view/admin_user_list_page.dart';
import 'package:traxx_wepapp/view/authentication/login/email_verification_view.dart';
import 'package:traxx_wepapp/view/guest/guest_event_details.dart';
import 'package:traxx_wepapp/view/guest/respond/respond_screen.dart';
import 'package:traxx_wepapp/view/admin/create_event/create_edit_event_view.dart';
import 'package:traxx_wepapp/view/admin/event_details/host_event_details_view.dart';
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
import 'package:traxx_wepapp/widgets/app_scaffold.dart';
import 'package:traxx_wepapp/widgets/content_wrapper.dart';
import 'package:traxx_wepapp/widgets/event_loader.dart';

/// Router setup for the Traxx application.
/// Currently implementing basic navigation structure with go_router.
///

/// Key for the host section's nested navigation
final GlobalKey<NavigatorState> hostNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> guestNavigationKey =
    GlobalKey<NavigatorState>();

///
/// Structure:
/// - Public routes (welcome, about, contact)
/// - Host section with nested navigation
GoRouter buildRouter() {
  final eventController = Get.find<EventController>();
  final authController = Get.find<AuthController>();
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoute.welcome.path,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.welcome.path,
        builder: (context, state) {
          final User? currentUser = FirebaseAuth.instance.currentUser;

          if (currentUser != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print(
                  'Router: User already signed in, go straight to host events');
              pushAndRemoveAllRoute(AppRoute.hostEvents, context);
            });
          }

          return const WelcomeView();
        },
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
          print('dasdadlaskdjkasjdlkasjdlkasjdlkasjdlkasjdlkasjdlkas');
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

      //HOST SHELL ROUTE
      ShellRoute(
        redirect: (context, state) {
          if (!authController.isAuthenticated) {
            print('Redirecting to welcome');
            return AppRoute.welcome.path;
          }

          if (!authController.isAuthenticatedAndVerified) {
            print('Redirecting to email verification');
            return AppRoute.emailVerification.path;
          }

          if (!authController.companyInfoExists) {
            print('Redirecting to organisation info form');
            return AppRoute.hostOrganisationInfoForm.path;
          }
          print('redirecting in host shell route passed');
          return null;
        },
        navigatorKey: hostNavigatorKey,
        builder: (context, state, child) {
          // Check if user is authenticated
          final User? currentUser = FirebaseAuth.instance.currentUser;
          // if (currentUser == null || !currentUser.emailVerified) {
          if (currentUser == null) {
            // If user is not authenticated, redirect to welcome
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushAndRemoveAllRoute(AppRoute.welcome, context);
              // pushAndRemoveAllRoute(AppRoute.emailVerification, context);
            });
            return Center(child: CircularProgressIndicator());
          }

          final eventListController = Get.find<EventListController>();
          final authController = Get.find<AuthController>();
          Get.put(VenuesController());
          Get.put(MenusController());
          Get.put(EventsController());
          Get.put(OrganisationController(authController.organisationId!));
          Get.put(UsersAndRolesController());

          final location = state.matchedLocation;
          final isQuestionsPage =
              location.startsWith(AppRoute.hostQuestions.path) ||
                  location.startsWith(AppRoute.hostQuestionSets.path) ||
                  location.startsWith(AppRoute.hostQuestionSetQuestions.path);

          return Obx(() {
            try {
              if (eventListController.isLoading.value ||
                  authController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              final location = state.matchedLocation;

              // Treat these paths as Google Forms–style question pages
              final isQuestionsPage = location
                      .startsWith(AppRoute.hostQuestionSets.path) ||
                  location.startsWith(AppRoute.hostQuestions.path) ||
                  location.startsWith(AppRoute.hostQuestionSetQuestions.path);

              const Color _gfBackground = Color(0xFFF4F0FB);

              return NavigationRailWrapper(
                child: ContentWrapper(
                  // ✅ All non-question pages keep the old grey background
                  // ✅ Question pages use the SAME lavender as in the screen files (_gfBackground)
                  contentColor: isQuestionsPage
                      ? _gfBackground // Color(0xFFF4F0FB)
                      : const Color.fromARGB(255, 247, 247, 247),
                  header: getPageHeader(state),
                  child: child,
                ),
              );
              // return AppScaffold(
              //   body:
              //       NavigationRailWrapper(child: ContentWrapper(child: child)),
              //   role: 'host',
              //   name: name,
              //   onLogout: authController.logout,
              // );
            } catch (e) {
              print('Exception in host shell route builder: $e');
              return Container(); //Temporary
              // Error Handling or redirection
            }
          });
        },
        routes: [
          GoRoute(
            path: AppRoute.hostEvents.path,
            builder: (context, state) => EventListScreen(),
          ),
          GoRoute(
            path: AppRoute.hostMenus.path,
            builder: (context, state) => MenusView(),
          ),
          GoRoute(
            path: AppRoute.hostVenues.path,
            builder: (context, state) => VenuesView(),
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
            // builder: (context, state) => AdminUserListPage(),
            builder: (context, state) {
              return AdminUserListPage();
            },
          ),
          /*  GoRoute(
              path: AppRoute.hostQuestions.path,
              builder: (context, state) => HostQuestionsScreen(),
            ), */
          // 🔹 NEW: Question Sets list page
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
                questionSetTitle: Uri.decodeComponent(setTitle),
                questionSetDescription: Uri.decodeComponent(setDescription),
              );
            },
          ),

          GoRoute(
            path: AppRoute.hostQuestionSetQuestions.path,
            builder: (context, state) {
              final setId = state.pathParameters[
                  AppRoute.hostQuestionSetQuestions.placeholder]!;
              final setTitle = Uri.decodeComponent(
                state.uri.queryParameters['setTitle'] ?? 'Question set',
              );
              final setDescription = Uri.decodeComponent(
                  state.uri.queryParameters['setDescription'] ?? '');
              return HostQuestionsScreen(
                questionSetId: setId,
                questionSetTitle: setTitle,
                questionSetDescription: setDescription,
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
          // GoRoute(
          //   path: AppRoute.eventDetails.path,
          //   builder: (context, state) {
          //     final Event? selectedEvent = eventController.selectedEvent.value;
          //     if (selectedEvent != null) {
          //       print('Returning existing selected event');
          //       return HostEventDetailsView(event: selectedEvent);
          //     }

          //     // final Event? event;
          //     // if (state.extra != null && state.extra is Event) {
          //     //   event = state.extra as Event;
          //     // } else {
          //     //   event = null;
          //     // }
          //     final eventId =
          //         state.pathParameters[AppRoute.eventDetails.placeholder]!;
          //     return FutureBuilder<Event>(
          //       future: EventFetcher.fetchEvent(eventId),
          //       builder: (context, snapshot) {
          //         if (snapshot.connectionState == ConnectionState.waiting) {
          //           return Center(child: CircularProgressIndicator());
          //         }
          //         if (snapshot.hasError) {
          //           return Center(child: Text('Error: ${snapshot.error}'));
          //         }
          //         eventController.setSelectedEvent(snapshot.data!);

          //         return HostEventDetailsView(event: snapshot.data!);
          //       },
          //     );
          //     // return HostEventDetailsView(event: selectedEvent);
          //   },
          //   // builder: (context, state) => HostEventDetailsView(),
          // ),
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
            // builder: (context, state) async {
            //   final Event? event;
            //   if (state.extra != null && state.extra is Event) {
            //     event = state.extra as Event;
            //   } else {
            //     event = null;
            //   }
            //   final eventId =
            //       state.pathParameters[AppRoute.eventDetails.placeholder]!;
            //       //helper function that accepts event id and event object and returns event object
            //       Event finalEvent = await EventFetcher.fetchEvent(event, eventId);
            //   return SetMenusView(event: finalEvent);
            // },
          ),
          // GoRoute(
          //   path: AppRoute.eventMenus.path,
          //   builder: (context, state) => SetMenusView(),
          // ),
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
        ],
      ),
      // Guest Shell Route
      ShellRoute(
        navigatorKey: guestNavigationKey,
        builder: (context, state, child) {
          final eventListController = Get.find<EventListController>();
          final authController = Get.find<AuthController>();
          return Obx(() {
            try {
              if (eventListController.isLoading.value ||
                  authController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final location = state.matchedLocation;

              // Treat these paths as Google Forms–style question pages
              final isQuestionsPage = location
                      .startsWith(AppRoute.hostQuestionSets.path) ||
                  location.startsWith(AppRoute.hostQuestions.path) ||
                  location.startsWith(AppRoute.hostQuestionSetQuestions.path);

              const Color _gfBackground = Color(0xFFF4F0FB);

              if (isQuestionsPage) {
                // ✅ QUESTION PAGES:
                // Header is drawn OUTSIDE ContentWrapper so it spans full width.
                return NavigationRailWrapper(
                  child: Column(
                    children: [
                      // full-width header
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 40,
                          right: 40,
                          top: 24,
                          bottom: 8,
                        ),
                        child: getPageHeader(state),
                      ),
                      // content area with lavender background + limited-width body
                      Expanded(
                        child: ContentWrapper(
                          contentColor: _gfBackground,
                          // no header here – body only
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // ✅ ALL OTHER PAGES – behave exactly as before
                return NavigationRailWrapper(
                  child: ContentWrapper(
                    contentColor: const Color.fromARGB(255, 247, 247, 247),
                    header: getPageHeader(state),
                    child: child,
                  ),
                );
              }
            } catch (e) {
              return Container(); //Temporary
            }
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
          // GoRoute(
          //   path: AppRoute.guestEventDetails.path,
          //   builder: (context, state) {
          //     final Event? event;
          //     if (state.extra != null && state.extra is Event) {
          //       event = state.extra as Event;
          //     } else {
          //       event = null;
          //     }
          //     final eventId =
          //         state.pathParameters[AppRoute.guestEventDetails.placeholder]!;
          //     // return GuestEventDetails(eventId: eventId, event: event);
          //     return GuestEventDetails();
          //   },
          // ),
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
