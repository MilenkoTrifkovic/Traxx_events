// Routes definition using enums for better type safety and organization
enum AppRoute {
  // Base routes
  welcome('/welcome'),

  // Host routes
  host('/host'),
  hostEvents('/host-events'),
  hostCreateEvent('/host-create-event'),

  eventDetails('/event-details'),
  eventQuestions('/event-questions'),
  eventMenus('/event-menus'),
  eventGuests('/event-guests'),

  // Guest routes

  // Planner routes

  // Other routes
  aboutView('/about'),
  contactView('/contact');

  final String path;
  const AppRoute(this.path);

  String get value => path;

  /// Convert a path string to an AppRoute
  static AppRoute? fromPath(String path) {
    try {
      return AppRoute.values.firstWhere((route) => route.path == path);
    } catch (_) {
      return null;
    }
  }
}
