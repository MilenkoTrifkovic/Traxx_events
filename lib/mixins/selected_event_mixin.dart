import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/models/event.dart';

mixin SelectedEventMixin on GetxController {
  // Rxn<Event> selectedEvent = Rxn<Event>();
  late final Rx<Event> selectedEvent;

  final EventController eventController = Get.find<EventController>();

  @override
  void onInit() {
    selectedEvent = Rx<Event>(
        eventController.selectedEvent.value!); //sets the current value
    // selectedEvent.value =
    //     eventController.selectedEvent.value;
    ever(eventController.selectedEvent, (event) {
      selectedEvent.value = event!;
    });
    super.onInit();
  }

  void updateEvent(Event Function(Event) updater) {
    final updated = updater(selectedEvent.value);
    selectedEvent.value = updated;
    eventController.setSelectedEvent(updated);
  }
}
