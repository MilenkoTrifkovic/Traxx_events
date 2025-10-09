import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/helper/fetch_event.dart';
import 'package:traxx_wepapp/models/event.dart';

class EventLoader extends StatelessWidget {
  final EventController eventController;
  final String eventId;
  final Widget Function(BuildContext context, Event event) builder;
  const EventLoader(
      {super.key,
      required this.eventController,
      required this.eventId,
      required this.builder});

  @override
  Widget build(BuildContext context) {
    final Event? selectedEvent = eventController.selectedEvent.value;
    if (selectedEvent != null) {
      return builder(context, selectedEvent);
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

        return builder(context, snapshot.data!);
      },
    );
  }
}
