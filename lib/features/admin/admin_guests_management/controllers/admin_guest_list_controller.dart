import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/guest_model_csv_parser.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/guest_model_xlsx_parser.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminGuestListController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();

  /// Controller for a search input used to filter guests by name or email.
  final searchController = TextEditingController();

  final selectedCountry = RxnString();
  final selectedState = RxnString();
  final selectedGender = Rxn<Gender>();

  /// Maximum number of guests this guest can invite (0 by default)
  final maxGuestInvite = 0.obs;

  /// Whether the guest is disabled. Defaults to false (enabled).
  final isDisabled = false.obs;

  final guests = <GuestModel>[].obs;
  final filteredGuests = <GuestModel>[].obs;

  /// Paginated subset of [filteredGuests] for the current page.
  final pagedGuests = <GuestModel>[].obs;

  /// Current page index (0-based).
  final currentPage = 0.obs;

  /// Number of items per page.
  final int pageSize = 50;

  final isInitialized = false.obs;

  late String eventId;

  final _uuid = const Uuid();

  void setEventId(String id) {
    eventId = id;
    _listenToGuestChanges();
  }

  String _newToken() {
    // creates a long token similar to your screenshot (64-ish chars)
    return (_uuid.v4() + _uuid.v4()).replaceAll('-', '');
  }

  // ---------------------------
  // Realtime listener
  // ---------------------------

  void _listenToGuestChanges() {
    FirebaseFirestore.instance
        .collection("guests")
        .where("eventId", isEqualTo: eventId)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs
          .map((d) => GuestModel.fromFirestore(d.data(), d.id))
          .toList();

      guests.assignAll(list);
      filteredGuests.assignAll(list);
      // Reset pagination whenever the underlying filtered list changes.
      currentPage.value = 0;
      _updatePagination();
      isInitialized.value = true;
    });
  }

  Future<Map<String, dynamic>> _getEventMeta() async {
    final byDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    if (byDoc.exists && byDoc.data() != null) return byDoc.data()!;

    final q = await FirebaseFirestore.instance
        .collection('events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Event not found for eventId=$eventId');
    }
    return q.docs.first.data();
  }

  Future<Map<String, dynamic>> _getEventData(String eventId) async {
    final byDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    if (byDoc.exists) return byDoc.data()!;

    final q = await FirebaseFirestore.instance
        .collection('events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) throw Exception('Event not found for eventId=$eventId');
    return q.docs.first.data();
  }

  Future<void> _createInvitationForGuest({
    required String guestId,
    required String guestEmail,
  }) async {
    final eventData = await _getEventData(eventId);

    final orgId = (eventData['organisationId'] ?? '').toString();
    final setId =
        (eventData['selectedDemographicQuestionSetId'] ?? '').toString();

    if (orgId.isEmpty) throw Exception('Event.organisationId missing');
    if (setId.isEmpty)
      throw Exception('Event.selectedDemographicQuestionSetId missing');

    final invRef = FirebaseFirestore.instance.collection('invitations').doc();
    final invId = invRef.id;

    final expiresAt =
        Timestamp.fromDate(DateTime.now().add(const Duration(days: 14)));

    await invRef.set({
      'invitationId': invId,
      'eventId': eventId,
      'organisationId': orgId,
      'guestId': guestId,
      'guestEmail': guestEmail,
      'demographicQuestionSetId': setId,
      'token': _newToken(),
      'expiresAt': expiresAt,
      'used': false,

      // match your screenshot fields
      'sent': false,
      'sendError': null,
      'createdAt': FieldValue.serverTimestamp(),
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------
  // Add Guest
  // ---------------------------

  /// Returns true on success, false on failure.
  /// Create (returns true on success)
  Future<bool> submitForm() async {
    if (!validateForm()) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('guests').doc();
      final guestId = docRef.id;

      final data = <String, dynamic>{
        'guestId': guestId,
        'name': name.text.trim(),
        'email': email.text.trim(),
        'address': address.text.trim(),
        'city': city.text.trim(),
        'country': selectedCountry.value,
        'state': selectedState.value,
        'gender': selectedGender.value?.name,
        'isDisabled': isDisabled.value,
        'isInvited': false, // Default to not invited
        'maxGuestInvite': maxGuestInvite.value,
        'eventId': eventId,
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      debugPrint('submitForm: guest created, id=$guestId');
      return true;
    } catch (e, st) {
      debugPrint('submitForm error: $e\n$st');
      return false;
    }
  }

  /// Update (returns true on success). If the document doesn't exist it will create it.
  Future<bool> updateGuest() async {
    if (!validateForm()) return false;

    if (_currentGuestId == null || _currentGuestId!.isEmpty) {
      debugPrint('updateGuest: _currentGuestId is null/empty — cannot update');
      return false;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('guests').doc(_currentGuestId);

      // Check existence
      final snapshot = await docRef.get();
      final data = <String, dynamic>{
        "name": name.text.trim(),
        "email": email.text.trim(),
        "address": address.text.trim(),
        "city": city.text.trim(),
        "country": selectedCountry.value,
        "state": selectedState.value,
        "gender": selectedGender.value?.name,
        "isDisabled": isDisabled.value,
        "maxGuestInvite": maxGuestInvite.value,
        "modifiedAt": FieldValue.serverTimestamp(),
      };

      if (snapshot.exists) {
        await docRef.update(data);
        debugPrint('updateGuest: updated existing guest id=$_currentGuestId');
      } else {
        // Document missing — create with provided id so future updates succeed
        await docRef.set({
          ...data,
          'guestId': _currentGuestId,
          'isInvited': false, // Default to not invited for new docs
          'eventId': eventId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
            'updateGuest: doc not found — created new guest doc id=$_currentGuestId');
      }

      return true;
    } catch (e, st) {
      debugPrint('updateGuest error: $e\n$st');
      return false;
    }
  }

  /// Updates a guest directly using a GuestModel object (for inline edits)
  Future<bool> updateGuestDirectly(GuestModel guest) async {
    if (guest.guestId == null || guest.guestId!.isEmpty) {
      debugPrint('updateGuestDirectly: guestId is null/empty — cannot update');
      return false;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('guests').doc(guest.guestId);

      await docRef.update(guest.toFirestoreUpdate());
      debugPrint('updateGuestDirectly: updated guest id=${guest.guestId}');
      return true;
    } catch (e, st) {
      debugPrint('updateGuestDirectly error: $e\n$st');
      return false;
    }
  }

  String? _currentGuestId;

  // ---------------------------
  // Prepare form for Edit
  // ---------------------------

  void updateAllFields(GuestModel guest) {
    _currentGuestId = guest.guestId;

    // Basic string fields
    name.text = guest.name;
    email.text = guest.email;
    address.text = guest.address ?? '';
    city.text = guest.city ?? '';

    // Country / State (nullable)
    selectedCountry.value = guest.country;
    selectedState.value = guest.state;

    selectedGender.value = guest.gender;

    // isDisabled flag
    // GuestModel.isDisabled is non-nullable in current model, assign directly
    isDisabled.value = guest.isDisabled;

    // maxGuestInvite
    maxGuestInvite.value = guest.maxGuestInvite;

    // // Gender: map from stored String to Gender enum safely (case-insensitive)
    // if (guest.gender != null && guest.gender!.isNotEmpty) {
    //   final genderStr = guest.gender!.toLowerCase().trim();
    //   // Try matching by enum name (case-insensitive), otherwise fallback to preferNotToSay
    //   try {
    //     selectedGender.value = Gender.values.firstWhere(
    //       (g) => g.name.toLowerCase() == genderStr,
    //       orElse: () {
    //         // Additional mapping if you saved values differently (e.g. 'male','female','other')
    //         if (genderStr == 'm' || genderStr == 'male') return Gender.male;
    //         if (genderStr == 'f' || genderStr == 'female') return Gender.female;
    //         if (genderStr == 'prefer_not_to_say' ||
    //             genderStr == 'prefernotto' ||
    //             genderStr == 'prefer not to say') {
    //           return Gender.preferNotToSay;
    //         }
    //         // Last resort fallback
    //         return Gender.preferNotToSay;
    //       },
    //     );
    //   } catch (_) {
    //     // Shouldn't reach here because of orElse, but keep defensive fallback
    //     selectedGender.value = Gender.preferNotToSay;
    //   }
    // } else {
    //   selectedGender.value = null;
    // }
  }

  // ---------------------------
  // Delete Guest
  // ---------------------------

  Future<void> deleteGuest(String guestId) async {
    await FirebaseFirestore.instance.collection("guests").doc(guestId).delete();
  }

  // ---------------------------
  // File Upload (CSV/XLSX)
  // ---------------------------

  /// Uploads guests from a CSV or XLSX file.
  ///
  /// This method parses the file, validates the data, filters out duplicate emails,
  /// and saves unique guests to Firestore in a batch operation. Returns the number
  /// of guests added on success, or throws an exception on error.
  ///
  /// Expected file format:
  /// - Required columns: Name, Email
  /// - Optional columns: Address, City, State, Country, Gender
  ///
  /// @param file The PlatformFile to parse (CSV or XLSX)
  /// @returns A map with 'added' count and 'skipped' count
  /// @throws FormatException if file format is invalid
  /// @throws Exception if Firestore operation fails
  Future<Map<String, int>> uploadGuestsFromFile(PlatformFile file) async {
    try {
      final List<GuestModel> parsedGuests;

      // Parse file based on extension
      if (file.extension?.toLowerCase() == 'csv') {
        final parser = GuestModelCsvParser(eventId: eventId);
        parsedGuests = parser.parseFile(file);
      } else if (file.extension?.toLowerCase() == 'xlsx') {
        final parser = GuestModelXlsxParser(eventId: eventId);
        parsedGuests = parser.parseFile(file);
      } else {
        throw FormatException(
            'Unsupported file type. Please upload a CSV or XLSX file.');
      }

      if (parsedGuests.isEmpty) {
        return {'added': 0, 'skipped': 0};
      }

      // Get existing guest emails for this event to check for duplicates
      final existingEmails = guests.map((g) => g.email.toLowerCase()).toSet();

      // Filter out guests with duplicate emails and track skipped rows
      final List<GuestModel> uniqueGuests = [];
      int skippedCount = 0;

      for (final guest in parsedGuests) {
        final emailLower = guest.email.toLowerCase();
        if (existingEmails.contains(emailLower)) {
          skippedCount++;
        } else {
          uniqueGuests.add(guest);
          existingEmails
              .add(emailLower); // Add to set to catch duplicates within file
        }
      }

      if (uniqueGuests.isEmpty) {
        return {'added': 0, 'skipped': skippedCount};
      }

      // Save all unique guests to Firestore using batch write
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final guest in uniqueGuests) {
        final docRef = FirebaseFirestore.instance.collection('guests').doc();
        final guestId = docRef.id;

        final guestWithId = GuestModel(
          docId: guestId,
          guestId: guestId,
          name: guest.name,
          email: guest.email,
          eventId: eventId,
          address: guest.address,
          city: guest.city,
          state: guest.state,
          country: guest.country,
          gender: guest.gender,
          maxGuestInvite: guest.maxGuestInvite,
          isDisabled: false,
          isInvited: false,
        );

        batch.set(docRef, guestWithId.toFirestoreCreate());
        count++;
      }

      await batch.commit();
      debugPrint(
          'uploadGuestsFromFile: uploaded $count guests, skipped $skippedCount duplicates');
      return {'added': count, 'skipped': skippedCount};
    } catch (e, st) {
      debugPrint('uploadGuestsFromFile error: $e\n$st');
      rethrow;
    }
  }

  // ---------------------------
  // Invitation methods
  // ---------------------------

  Future<bool> inviteGuest(String guestId) async {
    try {
      final guestDoc = await FirebaseFirestore.instance
          .collection('guests')
          .doc(guestId)
          .get();
      if (!guestDoc.exists) return false;

      final guest = GuestModel.fromFirestore(guestDoc.data()!, guestDoc.id);

      if (guest.isDisabled == true) return false;
      if (guest.isInvited == true) return true;
      if (guest.email.trim().isEmpty) return false;

      final eventMeta = await _getEventMeta();
      final orgId = (eventMeta['organisationId'] ?? '').toString();
      final setId =
          (eventMeta['selectedDemographicQuestionSetId'] ?? '').toString();

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendInvitations');

      final res = await callable.call({
        'eventId': eventId,
        'organisationId': orgId.isEmpty ? null : orgId,
        'demographicQuestionSetId': setId.isEmpty ? null : setId,
        'invitations': [
          {
            'guestEmail': guest.email.trim(),
            'guestId': guest.guestId,
            'guestName': guest.name,
          }
        ],
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final invited = (data['invited'] ?? 0) as int;

      if (invited > 0) {
        await FirebaseFirestore.instance
            .collection('guests')
            .doc(guestId)
            .update({
          'isInvited': true,
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('inviteGuest email error: $e\n$st');
      return false;
    }
  }

  Future<int> inviteAllGuests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('guests')
          .where('eventId', isEqualTo: eventId)
          .where('isDisabled', isEqualTo: false)
          .where('isInvited', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final guestsToInvite = snapshot.docs
          .map((d) => GuestModel.fromFirestore(d.data(), d.id))
          .where((g) => g.email.trim().isNotEmpty)
          .toList();

      if (guestsToInvite.isEmpty) return 0;

      final eventMeta = await _getEventMeta();
      final orgId = (eventMeta['organisationId'] ?? '').toString();
      final setId =
          (eventMeta['selectedDemographicQuestionSetId'] ?? '').toString();

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendInvitations');

      final res = await callable.call({
        'eventId': eventId,
        'organisationId': orgId.isEmpty ? null : orgId,
        'demographicQuestionSetId': setId.isEmpty ? null : setId,
        'invitations': guestsToInvite
            .map((g) => {
                  'guestEmail': g.email.trim(),
                  'guestId': g.guestId,
                  'guestName': g.name,
                })
            .toList(),
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final results = (data['results'] as List?) ?? [];

      final sentEmails = results
          .where((r) => r is Map && r['status'] == 'sent')
          .map((r) => (r['guestEmail'] ?? '').toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (sentEmails.isEmpty) return 0;

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        final email =
            (doc.data()['email'] ?? '').toString().trim().toLowerCase();
        if (sentEmails.contains(email)) {
          batch.update(doc.reference, {
            'isInvited': true,
            'modifiedAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }

      await batch.commit();
      return count;
    } catch (e, st) {
      debugPrint('inviteAllGuests email error: $e\n$st');
      return 0;
    }
  }

  // ---------------------------
  // Form Validation
  // ---------------------------

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    name.clear();
    email.clear();
    address.clear();
    city.clear();

    selectedCountry.value = null;
    selectedState.value = null;
    selectedGender.value = null;

    isDisabled.value = false;
    maxGuestInvite.value = 0;
    _currentGuestId = null;
  }

  // ---------------------------
  // Guest filtering (search)
  // ---------------------------

  /// Filters the guests list by [query], matching against name and email
  /// (case-insensitive). If [query] is empty the full guests list is restored.
  void filterGuests(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      // restore full list
      filteredGuests.assignAll(guests);
      currentPage.value = 0;
      _updatePagination();
      return;
    }

    final results = guests.where((g) {
      final nameValue = g.name.toLowerCase();
      // GuestModel.email is non-nullable in current model, use toLowerCase directly
      final emailValue = g.email.toLowerCase();
      return nameValue.contains(q) || emailValue.contains(q);
    }).toList();

    filteredGuests.assignAll(results);
    // Reset to first page after filtering.
    currentPage.value = 0;
    _updatePagination();
  }

  /// Clears any active filter and resets the search controller.
  void clearFilter() {
    searchController.clear();
    filteredGuests.assignAll(guests);
    currentPage.value = 0;
    _updatePagination();
  }

  // ---------------------------
  // Pagination helpers
  // ---------------------------

  /// Update [pagedGuests] based on [currentPage] and [pageSize].
  void _updatePagination() {
    final total = filteredGuests.length;
    if (total == 0) {
      pagedGuests.clear();
      return;
    }

    final pages = (total + pageSize - 1) ~/ pageSize;
    if (currentPage.value >= pages) {
      currentPage.value = pages - 1;
    }

    final start = currentPage.value * pageSize;
    final items = filteredGuests.skip(start).take(pageSize).toList();
    pagedGuests.assignAll(items);
  }

  /// Total number of pages (at least 1 if there are items, otherwise 0).
  int get totalPages {
    final total = filteredGuests.length;
    if (total == 0) return 0;
    return (total + pageSize - 1) ~/ pageSize;
  }

  /// Move to the next page if possible.
  void nextPage() {
    final pages = totalPages;
    if (pages == 0) return;
    if (currentPage.value < pages - 1) {
      currentPage.value++;
      _updatePagination();
    }
  }

  /// Move to the previous page if possible.
  void prevPage() {
    if (filteredGuests.isEmpty) return;
    if (currentPage.value > 0) {
      currentPage.value--;
      _updatePagination();
    }
  }

  /// Jump to a specific page (0-based). Clamps to valid range.
  void goToPage(int page) {
    final pages = totalPages;
    if (pages == 0) return;
    final p = page.clamp(0, pages - 1);
    currentPage.value = p;
    _updatePagination();
  }

  @override
  void onClose() {
    // Dispose controllers to avoid leaks
    name.dispose();
    email.dispose();
    address.dispose();
    city.dispose();
    searchController.dispose();
    super.onClose();
  }
}
