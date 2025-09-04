import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/exeptions/exeptions.dart';
import 'package:traxx_wepapp/models/guest.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';

class SetGuestsController {
  RxBool isLoading = true.obs;
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final HostController _hostController = Get.find<HostController>();

  List<Guest> guests = [];
  RxInt guestLimit = 0.obs;
  RxInt currentGuestCount = 0.obs;

  Future<void> initializeGuestList() async {
    guests.clear();
    try {
      final eventId = _hostController.eventId;
      if (eventId == null) {
        throw Exception('Cannot load guests: No event selected.');
      }
      final fetchedGuests = await _firestoreServices.fetchGuests(eventId);
      guests.addAll(fetchedGuests);
      _sortGuestList();
      _addGuestsToGuestCount(fetchedGuests);
    } finally {
      guestLimit.value = _hostController.eventCapacity ?? 0;
      isLoading.value = false;
    }
  }

  void _addGuestsToGuestCount(List<Guest> guestsList) {
    for (var g in guestsList) {
      currentGuestCount += (1 + g.companions);
    }
  }

  void _sortGuestList() {
    guests.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<int> addGuest(String email, String name, int companions) async {
    if (!_checkIfEmailIsUnique(email)) {
      throw EmailInUseException();
    }
    if (_guestLimitExceeded(companions)) {
      throw GuestLimitExceededException();
    }
    final eventId = _hostController.selectedEvent.value!.id!;
    Guest guest = Guest();
    guest.email = email;
    guest.name = name;
    guest.companions = companions;
    String guestId = await _firestoreServices.saveGuest(eventId, guest);
    guest.id = guestId;
    int index = _findGuestIndex(guest);
    guests.insert(index, guest);
    currentGuestCount += (1 + companions);

    return index;
  }

  bool _checkIfEmailIsUnique(String email) {
    for (var element in guests) {
      if (element.email == email) {
        return false;
      }
    }
    return true;
  }

  bool _guestLimitExceeded(int companions) {
    final currentCount = currentGuestCount.value;
    final newState = currentCount + (companions + 1);
    return newState > guestLimit.value;
  }

  int _findGuestIndex(Guest guest) {
    if (guests.isEmpty) return 0;

    for (int i = 0; i < guests.length; i++) {
      if (guest.name.toLowerCase().compareTo(guests[i].name.toLowerCase()) <=
          0) {
        return i;
      }
    }
    return guests.length;
  }

  //remove guest
  Future<Guest> removeGuest(int index) async {
    final eventId = _hostController.selectedEvent.value!.id!;
    Guest removedItem = guests.removeAt(index);
    await _firestoreServices.deleteGuest(eventId, removedItem);
    currentGuestCount -= (1 + removedItem.companions);
    return removedItem;
  }

  //Implemented error handling with reactive variable
  Future<void> inviteGuest(Guest guest) async {
    final eventId = _hostController.selectedEvent.value!.id!;
    try {
      await _firestoreServices.inviteGuest(eventId, guest);
      guest.invited = true;
      _firestoreServices.updateGuest(eventId, guest);
    } on Exception catch (e) {
      print('Failed to invite guest: $e');
      rethrow;
    }
  }
}
