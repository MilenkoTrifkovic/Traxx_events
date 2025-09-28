// Routes definition using enums for better type safety and organization
enum AppRoute {
  // Base routes
  welcome('/welcome'),

  // Host routes
  host('/host'),
  hostEvents('/host-events'),
  hostCreateEvent('/host-create-event'),

  guestEvents('/guest-events'),
  // guestEventDetails('/guest-event-details/:value'),
  guestEventDetails('/guest-event-details/:eventId', 'eventId'),
  guestEventRespond('/guest-event-details/:eventId/respond', 'eventId'),

  eventDetails('/event-details/:eventId', 'eventId'),
  eventQuestions('/event-questions'),
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
