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
  hostVenues('/host-venues'),
  hostMenus('/host-menus'),

  /// 🔹 NEW: host menu set details
  hostMenuDetails('/host-menus/:menuId', 'menuId'),

  hostVenueDetails('/host-venue-details/:eventId', 'eventId'),
  hostQuestionSets('/host-question-sets'),
  hostSettings('/host-settings'),

  // NEW: questions for a specific set (HostQuestionsScreen)
  hostQuestionSetQuestions('/host-question-sets/:setId', 'setId'),
  hostQuestions('/host-questions'),
  hostCreateEvent('/host-create-event'),
  adminEventDetails('/host-event-details/:eventId', 'eventId'),

  // Guest / event routes ...
  guestEvents('/guest-events'),
  guestEventDetails('/guest-event-details/:eventId', 'eventId'),
  guestEventRespond('/guest-event-details/:eventId/respond', 'eventId'),
  eventDetails('/event-details/:eventId', 'eventId'),
  eventQuestions('/event-questions'),
  eventResponses('/event-responses/:eventId/responses', 'eventId'),
  eventMenus('/guest-event-details/:eventId/event-menus', 'eventId'),
  eventGuests('/event-guests'),

  // Public guest form route (you already have it hardcoded as '/demographics')
  demographics('/demographics'),

// Dev-only host route visible in sidebar
  // hostDemographics('/host-demographics'),

  // Other
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
  final String? placeholder;

  const AppRoute(this.path, [this.placeholder]);
}
