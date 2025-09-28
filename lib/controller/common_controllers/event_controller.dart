import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';

class EventController {
  final Rxn<Event> selectedEvent = Rxn<Event>();

  // Getter
  // Event? get selectedEvent => selectedEvent.value;

  // Setter
  /// Updates the selected event
  ///
  /// Parameters:
  ///   event: The Event object to set as selected
  void setSelectedEvent(Event event) {
    selectedEvent.value = event;
  }
}
