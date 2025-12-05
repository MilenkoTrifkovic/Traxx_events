// Routes definition using enums for better type safety and organization
enum AppRoute {
  // Base routes
  welcome('/welcome'),
  signup('/signup'),
  emailVerification('/email-verification'),

  // Host routes
  host('/host'),
  hostOrganisationInfoForm('/host-organisation-info-form'),
  hostEvents('/host-events'),
  hostRoleSelection('/host-role-selection'),
  // hostRoletest('/hosdasdasdas'),
  hostVenues('/host-venues'),
  hostMenus('/host-menus'),
  hostVenueDetails('/host-venue-details/:eventId', 'eventId'),
  // NEW: question sets list page
  hostQuestionSets('/host-question-sets'),

  // NEW: questions for a specific set (HostQuestionsScreen)
  hostQuestionSetQuestions('/host-question-sets/:setId', 'setId'),
  hostQuestions('/host-questions'),
  hostCreateEvent('/host-create-event'),

  adminEventDetails('/host-event-details/:eventId', 'eventId'),

  guestEvents('/guest-events'),
  // guestEventDetails('/guest-event-details/:value'),
  guestEventDetails('/guest-event-details/:eventId', 'eventId'),
  guestEventRespond('/guest-event-details/:eventId/respond', 'eventId'),

  eventDetails('/event-details/:eventId', 'eventId'),
  eventQuestions('/event-questions'),
  eventResponses('/event-responses/:eventId/responses', 'eventId'),
  // eventMenus('/event-menus'),
  eventMenus('/guest-event-details/:eventId/event-menus', 'eventId'),
  eventGuests('/event-guests'),

  // Guest routes

  // Planner routes

  // Other routes
  aboutView('/about'),
  contactView('/contact');

  static AppRoute? fromPath(String path) {
    try {
      return AppRoute.values
          .firstWhere((route) => path.contains(route.path.split('/:')[0]));
    } catch (_) {
      return null;
    }
  }

  final String path;
  final String? placeholder; // placeholder je sada opcionalan

  const AppRoute(this.path, [this.placeholder]);
}
