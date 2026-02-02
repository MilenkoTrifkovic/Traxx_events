// Routes definition using enums for better type safety and organization
enum AppRoute {
  // Base routes
  welcome('/welcome'),
  signup('/signup'),
  emailVerification('/email-verification'),
  resetPassword('/reset-password'),

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
  hostBuyCredits('/host-buy-credits'),

  // NEW: questions for a specific set (HostQuestionsScreen)
  hostQuestionSetQuestions('/host-question-sets/:setId', 'setId'),
  hostQuestions('/host-questions'),
  hostCreateEvent('/host-create-event'),
  adminEventDetails('/host-event-details/:eventId', 'eventId'),
  hostQuestionRules('/host-question-rules'),

  // Guest / event routes ...
  guestEvents('/guest-events'),
  guestEventDetails('/guest-event-details/:eventId', 'eventId'),
  guestEventRespond('/guest-event-details/:eventId/respond', 'eventId'),

  eventDetails('/event-details/:eventId', 'eventId'),

  // ✅ NEW: Event analyzer main page (separate page)
  eventAnalyzer('/event-details/:eventId/analyzer', 'eventId'),

  eventQuestions('/event-questions'),
  eventResponses('/event-responses/:eventId/responses', 'eventId'),
  eventMenus('/guest-event-details/:eventId/event-menus', 'eventId'),
  eventDemographicAnalyzer(
      '/event-details/:eventId/demographic-analyzer', 'eventId'),
  eventMenuAnalyzer('/event-details/:eventId/menu-analyzer', 'eventId'),
  eventGuests('/event-guests'),
  guestSidePreview('/event-details/:eventId/guest-preview', 'eventId'),

  // Public guest response routes
  // Public guest response routes
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

  /// ✅ Improved matcher:
  /// Correctly differentiates routes like:
  ///   /event-details/:eventId
  ///   /event-details/:eventId/analyzer
  /// by using a prefix-regex and choosing the most specific (longest) match.
  static AppRoute? fromPath(String path) {
    final clean = path.split('?').first;

    AppRoute? best;
    int bestLen = -1;

    for (final r in AppRoute.values) {
      final re = RegExp(_prefixRegexFor(r.path));
      if (!re.hasMatch(clean)) continue;

      final score = r.path.length; // longer route = more specific
      if (score > bestLen) {
        best = r;
        bestLen = score;
      }
    }
    return best;
  }

  static String _prefixRegexFor(String routePath) {
    // Build: ^/event-details/[^/]+/analyzer(?:/|$)
    final parts = routePath.split('/');
    final b = StringBuffer('^');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == 0) continue; // first is '' because path starts with '/'
      b.write('\/');
      if (part.startsWith(':')) {
        b.write(r'[^\/]+');
      } else {
        b.write(RegExp.escape(part));
      }
    }

    b.write(r'(?:\/|$)');
    return b.toString();
  }

  final String path;
  final String? placeholder;

  const AppRoute(this.path, [this.placeholder]);
}
