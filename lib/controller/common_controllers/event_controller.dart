import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';

class EventController {
  final Rxn<Event> selectedEvent = Rxn<Event>();
  void setSelectedEvent(Event event) {
    selectedEvent.value = event;
  }
}
