import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/guest_rsvp_status.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/guest_model_csv_parser.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/guest_model_xlsx_parser.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminGuestListController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Add FirestoreServices instance
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();

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
    _listenToInvitationRsvpChanges();
  }

  final rsvpByGuestId = <String, GuestRsvpStatus>{}.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invitationSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _guestSub;

  String _newToken() {
    // creates a long token similar to your screenshot (64-ish chars)
    return (_uuid.v4() + _uuid.v4()).replaceAll('-', '');
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to country changes and clear state when country is not USA
    ever(selectedCountry, (country) {
      if (country != null && country != 'United States') {
        selectedState.value = null;
      }
    });
  }

  // ---------------------------
  // Realtime listener
  // ---------------------------

  void _listenToGuestChanges() {
    _guestSub?.cancel();
    _guestSub = FirebaseFirestore.instance
        .collection("guests")
        .where("eventId", isEqualTo: eventId)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs
          .map((d) => GuestModel.fromFirestore(d.data(), d.id))
          .toList();

      guests.assignAll(list);
      filteredGuests.assignAll(list);
      currentPage.value = 0;
      _updatePagination();
      isInitialized.value = true;
    });
  }

  void _listenToInvitationRsvpChanges() {
    _invitationSub?.cancel();

    _invitationSub = FirebaseFirestore.instance
        .collection('invitations')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .listen((snapshot) {
      final Map<String, GuestRsvpStatus> map = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final guestId = (data['guestId'] ?? '').toString().trim();
        if (guestId.isEmpty) continue;

        final hasResponded = data['hasResponded'] == true;

        bool? isAttending;
        final v = data['isAttending'];
        if (v is bool) isAttending = v;

        // choose the most recent if duplicates ever exist
        DateTime? updatedAt;
        final ts =
            data['rsvpSubmittedAt'] ?? data['modifiedAt'] ?? data['createdAt'];
        if (ts is Timestamp) updatedAt = ts.toDate();

        final existing = map[guestId];
        if (existing == null) {
          map[guestId] = GuestRsvpStatus(
            hasResponded: hasResponded,
            isAttending: isAttending,
            updatedAt: updatedAt,
          );
        } else {
          final prev = existing.updatedAt;
          if (prev == null || (updatedAt != null && updatedAt.isAfter(prev))) {
            map[guestId] = GuestRsvpStatus(
              hasResponded: hasResponded,
              isAttending: isAttending,
              updatedAt: updatedAt,
            );
          }
        }
      }

      rsvpByGuestId.assignAll(map);
      rsvpByGuestId.refresh();
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

  Future<bool> submitForm({bool skipValidate = false}) async {
    if (!skipValidate && !validateForm()) return false;

    try {
      final guest = GuestModel(
        name: name.text.trim(),
        email: email.text.trim(),
        eventId: eventId,
        address: address.text.trim().isNotEmpty ? address.text.trim() : null,
        city: city.text.trim().isNotEmpty ? city.text.trim() : null,
        country: selectedCountry.value,
        state: selectedState.value,
        gender: selectedGender.value,
        isDisabled: isDisabled.value,
        isInvited: false,
        maxGuestInvite: maxGuestInvite.value,
      );

      await _firestoreServices.saveGuest(guest);
      return true;
    } catch (e, st) {
      debugPrint('submitForm error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateGuest({bool skipValidate = false}) async {
    if (!skipValidate && !validateForm()) return false;
    if (_currentGuestId == null || _currentGuestId!.isEmpty) return false;

    try {
      final guest = GuestModel(
        guestId: _currentGuestId,
        name: name.text.trim(),
        email: email.text.trim(),
        eventId: eventId,
        address: address.text.trim().isNotEmpty ? address.text.trim() : null,
        city: city.text.trim().isNotEmpty ? city.text.trim() : null,
        country: selectedCountry.value,
        state: selectedState.value,
        gender: selectedGender.value,
        isDisabled: isDisabled.value,
        maxGuestInvite: maxGuestInvite.value,
        isInvited: false,
      );

      await _firestoreServices.updateGuest(guest);
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
      // Use FirestoreServices to update (preserves batchId and other fields)
      await _firestoreServices.updateGuest(guest);
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

      // Save all unique guests to Firestore using the service layer
      // Note: We can't use batch writes here because batch ID generation requires async queries
      int count = 0;

      for (final guest in uniqueGuests) {
        try {
          // Use FirestoreServices.saveGuest which will generate batch ID
          await _firestoreServices.saveGuest(guest);
          count++;
        } catch (e) {
          debugPrint('Failed to save guest ${guest.email}: $e');
          // Continue with next guest even if one fails
        }
      }

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

  Future<bool> inviteGuest(String guestId, {bool forceResend = false}) async {
    try {
      final guestDoc = await FirebaseFirestore.instance
          .collection('guests')
          .doc(guestId)
          .get();
      if (!guestDoc.exists) return false;

      final guest = GuestModel.fromFirestore(guestDoc.data()!, guestDoc.id);

      if (guest.isDisabled == true) return false;
      if (guest.email.trim().isEmpty) return false;

      // allow resend
      if (guest.isInvited == true && !forceResend) {
        return true;
      }

      final eventMeta = await _getEventMeta();
      final orgId = (eventMeta['organisationId'] ?? '').toString();
      final setId =
          (eventMeta['selectedDemographicQuestionSetId'] ?? '').toString();

      final eventsController = Get.find<EventsController>();
      final invitationCode =
          eventsController.getInvitationCodeByEventId(eventId);

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendInvitations');

      final res = await callable.call({
        'eventId': eventId,
        'organisationId': orgId.isEmpty ? null : orgId,
        'demographicQuestionSetId': setId.isEmpty ? null : setId,
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode,
        'invitations': [
          {
            'guestEmail': guest.email.trim(),
            'guestId': guestId, // ✅ doc.id
            'guestName': guest.name,
            'maxGuestInvite': guest.maxGuestInvite,
            if (guest.batchId != null && guest.batchId!.trim().isNotEmpty)
              'batchId': guest.batchId,
          }
        ],
      });

      final data = Map<String, dynamic>.from(res.data as Map);

      final ok = data['ok'] == true;

      final invitedCountRaw = data['invited'];
      final invitedCount = invitedCountRaw is num
          ? invitedCountRaw.toInt()
          : int.tryParse((invitedCountRaw ?? '0').toString()) ?? 0;

      final resultsRaw = data['results'];
      final List results = resultsRaw is List ? resultsRaw : const [];

      final bool sentByResult = results.any((r) {
        if (r is! Map) return false;
        final m = Map<String, dynamic>.from(r as Map);
        final status = (m['status'] ?? '').toString().toLowerCase();
        final rid = (m['guestId'] ?? '').toString().trim();
        return status == 'sent' && (rid.isEmpty || rid == guestId);
      });

      final success = ok && (invitedCount > 0 || sentByResult);

      if (!success) {
        debugPrint('Invite failed response: $data');
      }

      // ✅ IMPORTANT: do NOT update guests doc here anymore
      // Cloud Function now updates guests/{guestId}.isInvited reliably.

      return success;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
          'inviteGuest FirebaseFunctionsException: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('inviteGuest error: $e\n$st');
      return false;
    }
  }

  Future<int> inviteAllGuests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('guests')
          .where('eventId', isEqualTo: eventId)
          .where('isDisabled', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      // Build invitations using doc.id as guestId (CRITICAL)
      final invitations = snapshot.docs
          .map((doc) {
            final g = GuestModel.fromFirestore(doc.data(), doc.id);
            if (g.email.trim().isEmpty) return null;
            return {
              'guestEmail': g.email.trim(),
              'guestId': doc.id, // ✅ MUST be doc.id
              'guestName': g.name,
              'maxGuestInvite': g.maxGuestInvite,
              if (g.batchId != null && g.batchId!.trim().isNotEmpty)
                'batchId': g.batchId,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (invitations.isEmpty) return 0;

      final eventMeta = await _getEventMeta();
      final orgId = (eventMeta['organisationId'] ?? '').toString();
      final setId =
          (eventMeta['selectedDemographicQuestionSetId'] ?? '').toString();

      final eventsController = Get.find<EventsController>();
      final invitationCode =
          eventsController.getInvitationCodeByEventId(eventId);

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendInvitations');

      final res = await callable.call({
        'eventId': eventId,
        'organisationId': orgId.isEmpty ? null : orgId,
        'demographicQuestionSetId': setId.isEmpty ? null : setId,
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode,
        'invitations': invitations,
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final results = (data['results'] as List?) ?? [];

      // ✅ Collect guestIds that were successfully sent
      final sentGuestIds = results
          .where((r) => r is Map && r['status'] == 'sent')
          .map((r) => (r['guestId'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      if (sentGuestIds.isEmpty) return 0;

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final id in sentGuestIds) {
        batch.update(FirebaseFirestore.instance.collection('guests').doc(id), {
          'isInvited': true,
          'modifiedAt': FieldValue.serverTimestamp(),
          'lastInvitedAt': FieldValue.serverTimestamp(),
          'inviteSentCount': FieldValue.increment(1),
        });
        count++;
      }

      await batch.commit();
      return count;
    } catch (e, st) {
      debugPrint('inviteAllGuests error: $e\n$st');
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
    _guestSub?.cancel();
    _invitationSub?.cancel();
    name.dispose();
    email.dispose();
    address.dispose();
    city.dispose();
    searchController.dispose();
    super.onClose();
  }
}
