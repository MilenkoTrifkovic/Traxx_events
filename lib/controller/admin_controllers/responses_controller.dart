import 'package:get/get.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/mixins/selected_event_mixin.dart';
import 'package:traxx_wepapp/models/guest.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class ResponsesController extends GetxController with SelectedEventMixin {
  final List<Guest> guests;
  final List<MenuItemOld> menus;
  final List<GuestResponse> guestResponses;
  late final RxList<GuestResponse> filteredGuestResponses;

  ResponsesController._(this.guests, this.menus, this.guestResponses)
      : filteredGuestResponses = RxList.from(guestResponses);

  static Future<ResponsesController> create(String eventId) async {
    final responses = await _loadGuestResponses(eventId);
    final guests = await _loadEventGuests(eventId);
    final menus = await _loadEventMenus(eventId);

    return ResponsesController._(guests, menus, responses);
  }

  static Future<List<GuestResponse>> _loadGuestResponses(String eventId) async {
    FirestoreServices firestoreServices = Get.find<FirestoreServices>();
    List<GuestResponse> responses =
        await firestoreServices.fetchAllGuestResponses(eventId);
    return responses;
  }

  static Future<List<Guest>> _loadEventGuests(String eventId) async {
    FirestoreServices firestoreServices = Get.find<FirestoreServices>();
    final guests = await firestoreServices.fetchGuests(eventId);
    return guests;
  }

  static Future<List<MenuItemOld>> _loadEventMenus(String eventId) async {
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

  String guestName(String guestId) {
    final name = guests
        .firstWhere(
          (element) => element.id == guestId,
        )
        .name;
    return name;
  }

  String guestEmail(String guestId) {
    final email = guests
        .firstWhere(
          (element) => element.id == guestId,
        )
        .email;
    return email;
  }

  String menuName(String menuId) {
    final name = menus
        .firstWhere(
          (menu) => menu.menuItemId == menuId,
        )
        .dishName
        .capitalizeString();
    return name;
  }
}
