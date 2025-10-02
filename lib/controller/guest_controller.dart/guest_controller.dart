import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/extensions/guest_response_extensions.dart';
import 'package:traxx_wepapp/mixins/selected_event_mixin.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class GuestController extends GetxController with SelectedEventMixin {
  final errorMessage =
      ''.obs; //for error handling - UI listens and shows snackBar
  final List<GuestResponse> responses; //Loaded at instance creation
  final List<MenuItem> eventMenus;

  GuestController._({required this.responses, required this.eventMenus});
  // Create an instance of GuestController with pre-fetched guest responses.
  // This factory method ensures that the necessary data is loaded before the controller is used.
  static Future<GuestController> create(String eventId, String userId) async {
    FirestoreServices firestoreServices = Get.find<FirestoreServices>();

    final fetchedResponses =
        await firestoreServices.fetchGuestResponses(eventId, userId);
    final menus = await _loadEventMenus(eventId);
    print(fetchedResponses.length);
    return GuestController._(responses: fetchedResponses, eventMenus: menus);
  }

  static Future<List<MenuItem>> _loadEventMenus(String eventId) async {
    //ERROR handling
    FirestoreServices firestoreServices = Get.find<FirestoreServices>(); //added
    final StorageServices storageServices = Get.find<StorageServices>(); //added
    final menus = await firestoreServices.getMenus(eventId);

    for (final menu in menus) {
      if (menu.imagePath.isNotEmpty) {
        menu.imageUrl = await storageServices.loadImageURL(menu.imagePath);
      }
    }
    return menus;
  }

  List<Map<String, String>> getAllResponsesAsTableRows() {
    return responses
        .map((response) => response.toTableRow(eventMenus))
        .toList();
  }

  bool rsvpDeadlineValid() {
    DateTime now = DateTime.now();
    return selectedEvent.value.rsvpDeadline.isAfter(now);
  }

  String rsvpDeadline() {
    DateTime deadline = selectedEvent.value.rsvpDeadline;
    String timezone = selectedEvent.value.timezone;
    String deadlineText = DateFormat.yMd().format(deadline);
    return '$deadlineText - $timezone';
  }
}
