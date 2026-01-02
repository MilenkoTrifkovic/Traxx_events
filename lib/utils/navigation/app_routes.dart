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
  eventDemographicAnalyzer(
      '/event-details/:eventId/demographic-analyzer', 'eventId'),
  eventMenuAnalyzer('/event-details/:eventId/menu-analyzer', 'eventId'),
  eventGuests('/event-guests'),
  guestSidePreview('/event-details/:eventId/guest-preview', 'eventId'),

  // Public guest response routes
  guestLogin('/guest-login'),
  guestResponsesPreview('/guest-responses-preview'),
  guestResponse('/guest-response'),
  guestCompanions('/guest-companions'),
  guestCompanionsInfo('/guest-companions-info'),
  demographics('/demographics'),
  menuSelection('/menu-selection'),
  thankYou('/thank-you'),

// Dev-only host route visible in sidebar
  // hostDemographics('/host-demographics'),

  // Other
  aboutView('/about'),
  contactView('/contact'),
  calendarView('/calendar');

  static AppRoute? fromPath(String path) {
    final clean = path.split('?').first;

    AppRoute? best;
    int bestLen = -1;

    for (final r in AppRoute.values) {
      final base = r.path.split('/:').first; // e.g. /host-question-sets
      final matches = clean == base || clean.startsWith('$base/');
      if (matches && base.length > bestLen) {
        best = r;
        bestLen = base.length;
      }
    }
    return best;
  }

  final String path;
  final String? placeholder;

  const AppRoute(this.path, [this.placeholder]);
}
