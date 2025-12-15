
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/exeptions/exeptions.dart';
import 'package:traxx_wepapp/models/guest_dart.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/csv_parser.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/file_parser_abstract.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/xlsl_parser.dart';

class SetGuestsController {
  RxString errorMessage = ''.obs;
  RxBool isLoading = true.obs;
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  // final HostController _hostController = Get.find<HostController>();
  final EventListController _eventListController =
      Get.find<EventListController>();

  List<Guest_old> guests = [];
  RxInt guestLimit = 0.obs;
  RxInt currentGuestCount = 0.obs;

  Future<void> initializeGuestList() async {
    guests.clear();
    try {
      final eventId = _eventListController.eventId;
      if (eventId == null) {
        throw Exception('Cannot load guests: No event selected.');
      }
      final fetchedGuests = await _firestoreServices.fetchGuestsOld(eventId);
      guests.addAll(fetchedGuests);
      _sortGuestList();
      _addGuestsToGuestCount(fetchedGuests);
    } finally {
      guestLimit.value = _eventListController.eventCapacity ?? 0;
      isLoading.value = false;
    }
  }

  void _addGuestsToGuestCount(List<Guest_old> guestsList) {
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
    final eventId = _eventListController.selectedEvent.value!.eventId!;
    Guest_old guest = Guest_old();
    guest.email = email;
    guest.name = name;
    guest.companions = companions;
    String guestId = await _firestoreServices.saveGuestOld(eventId, guest);
    guest.id = guestId;
    int index = _findGuestIndex(guest);
    guests.insert(index, guest);
    currentGuestCount += (1 + companions);

    return index;
  }

  //Removes all existing guests and adds new guests from CSV or XLSX file
  Future<void> addGuestFromCsvXlsX(PlatformFile file) async {
    List<Guest_old> guests = [];
    int totalGuests = 0;
    final eventId = _eventListController.selectedEvent.value!.eventId!;
    FileParser fileParser =
        file.extension == 'csv' ? CsvParser() : XlsXParser();
    try {
      List<Guest_old> parsedGuests = fileParser.parseFile(file);
      for (var guest in parsedGuests) {
        guests.add(Guest_old(
            email: guest.email,
            name: guest.name,
            companions: guest.companions));
        totalGuests += (1 + guest.companions);
      }
      if (totalGuests > guestLimit.value) {
        throw Exception(
            'Guest limit exceeded. Limit is ${guestLimit.value}. You are trying to add $totalGuests guests.');
      }
      await _firestoreServices
          .deleteAllGuests(_eventListController.selectedEvent.value!.eventId!);
      await _firestoreServices.saveGuestList(eventId, guests);
    } on Exception catch (e) {
      _addError(e.toString());
    }
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

  int _findGuestIndex(Guest_old guest) {
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
  Future<Guest_old> removeGuest(int index) async {
    final eventId = _eventListController.selectedEvent.value!.eventId!;
    Guest_old removedItem = guests.removeAt(index);
    await _firestoreServices.deleteGuestOld(eventId, removedItem);
    currentGuestCount -= (1 + removedItem.companions);
    return removedItem;
  }

  //Implemented error handling with reactive variable
  Future<void> inviteGuest(Guest_old guest) async {
    final eventId = _eventListController.selectedEvent.value!.eventId!;
    try {
      await _firestoreServices.inviteGuest(eventId, guest);
      guest.invited = true;
      _firestoreServices.updateGuestOld(eventId, guest);
    } on Exception catch (e) {
      print('Failed to invite guest: $e');
      rethrow;
    }
  }

  void _addError(String error) {
    String message = error.split(':').last.trim();
    errorMessage.value = message;
  }

  void clearError() {
    errorMessage.value = '';
  }
}
