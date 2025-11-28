import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/guest_controller.dart';
import 'package:traxx_wepapp/helper/fetch_event.dart';
import 'package:traxx_wepapp/layout/header_resolver.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/custom_error_page.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/admin_event_details.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/venue_details_view.dart';
import 'package:traxx_wepapp/view/authentication/login/email_verification_view.dart';
import 'package:traxx_wepapp/view/authentication/signup/signup_view.dart';
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
import 'package:traxx_wepapp/view/info/about_view.dart';
import 'package:traxx_wepapp/view/info/contact_view.dart';
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
          // Check if user is already authenticated
          final User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            // If user is authenticated, redirect to host events
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushAndRemoveAllRoute(AppRoute.hostEvents, context);
            });
          }
          return WelcomeView();
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
        // builder: (context, state) => EmailValidationView(),
        builder: (context, state) {
          // final User? currentUser = FirebaseAuth.instance.currentUser;
          // if (currentUser != null && currentUser.emailVerified) {
          //   // If user is authenticated, redirect to host events
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     pushAndRemoveAllRoute(AppRoute.hostEvents, context);
          //   });
          // }
          // if (currentUser == null) {
          //   // If user is authenticated, redirect to host events
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     pushAndRemoveAllRoute(AppRoute.welcome, context);
          //   });
          // }
          return EmailVerificationView();
        },
      ),
      // GoRoute(
      //   path: AppRoute.signup.path,
      //   builder: (context, state) => SignupView(),
      // ),
      // GoRoute(
      //   path: AppRoute.aboutView.path,
      //   builder: (context, state) => AboutView(),
      // ),
      // GoRoute(
      //   path: AppRoute.contactView.path,
      //   builder: (context, state) => ContactView(),
      // ),
      GoRoute(
        redirect: (context, state) {
          if (!authController.isAuthenticated) {
            return AppRoute.welcome.path;
          }
          if (!authController.isAuthenticatedAndVerified) {
            return AppRoute.emailVerification.path;
          }
          if (authController.companyInfoExists.value == true) {
            return AppRoute.hostEvents.path;
          }
          return null;
        },
        path: AppRoute.hostOrganisationInfoForm.path,
        builder: (context, state) => OrganisationInfoPopupView(),
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
          if (authController.companyInfoExists.value == false) {
            print(
                'Company info exists? ${authController.companyInfoExists.value}');
            print('Redirecting to organisation info form');
            return AppRoute.hostOrganisationInfoForm.path;
          }
          return null;
        },
        navigatorKey: hostNavigatorKey,
        builder: (context, state, child) {
          // Check if user is authenticated
          final User? currentUser = FirebaseAuth.instance.currentUser;
          // if (currentUser == null || !currentUser.emailVerified) {
          if (currentUser == null) {
            // If user is not authenticated, redirect to welcome
            print('User not authenticated, redirecting to welcome PostFrame');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushAndRemoveAllRoute(AppRoute.welcome, context);
              // pushAndRemoveAllRoute(AppRoute.emailVerification, context);
            });
            return Center(child: CircularProgressIndicator());
          }

          final eventListController = Get.find<EventListController>();
          final authController = Get.find<AuthController>();
          Get.put(VenuesController());
          Get.put(EventsController());
          Get.put(OrganisationController(authController.organisationId!));

          return Obx(() {
            try {
              if (eventListController.isLoading.value ||
                  authController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              // final name = authController.userName.value;
              // print('Building host shell route for user: $name');
              print('State location: ${state.matchedLocation}');
              return NavigationRailWrapper(
                  child: ContentWrapper(
                header: getPageHeader(state),
                child: child,
              ));
              // return AppScaffold(
              //   body:
              //       NavigationRailWrapper(child: ContentWrapper(child: child)),
              //   role: 'host',
              //   name: name,
              //   onLogout: authController.logout,
              // );
            } catch (e) {
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
            path: AppRoute.hostVenues.path,
            builder: (context, state) => VenuesView(),
          ),
          GoRoute(
            path: AppRoute.hostVenueDetails.path,
            builder: (context, state) {
              final venueId =
                  state.pathParameters[AppRoute.hostVenueDetails.placeholder]!;
              return VenueDetailsView(venueId: venueId);
            },
          ),
          GoRoute(
            path: AppRoute.hostQuestions.path,
            builder: (context, state) => HostQuestionsScreen(),
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
                return Center(child: CircularProgressIndicator());
              }
              final name = authController.userName.value;
              return AppScaffold(
                body: ContentWrapper(child: child),
                role: 'guest',
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
