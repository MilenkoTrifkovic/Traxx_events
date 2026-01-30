import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invitationSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _guestSub;

  // Helps when keys don’t match perfectly (docId vs guestId)
  final Map<String, String> _guestKeyByEmailLower = {};

  // RSVP status map keyed by guestId/docId (whatever matches your table)
  final rsvpByGuestId = <String, GuestRsvpStatus>{}.obs;

  String _s(dynamic v) => (v ?? '').toString().trim();

  String _newToken() {
    // creates a long token similar to your screenshot (64-ish chars)
    return (_uuid.v4() + _uuid.v4()).replaceAll('-', '');
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;

    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;

    // ISO string like "2026-01-30T19:22:09.758Z"
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    // epoch millis (rare)
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is double) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }

    return null;
  }

  void setEventId(String id) {
    eventId = id;
    _listenToGuestChanges();

    // ✅ ONLY ONE RSVP LISTENER (includes companions)
    _listenInvitationsForRsvp();
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
  // Rebuild email->key index
  // ---------------------------

  void _rebuildGuestEmailIndex() {
    _guestKeyByEmailLower
      ..clear()
      ..addEntries(guests.map((g) {
        final emailLower = (g.email ?? '').toString().trim().toLowerCase();
        final key = ((g.guestId ?? '').toString().trim().isNotEmpty)
            ? g.guestId!.trim()
            : (g.docId ?? '').trim();
        return MapEntry(emailLower, key);
      }).where((e) => e.key.isNotEmpty && e.value.isNotEmpty));
  }

  // ---------------------------
  // Guests realtime listener
  // ---------------------------

  void _listenToGuestChanges() {
    _guestSub?.cancel();
    isInitialized.value = false;

    final baseQuery = FirebaseFirestore.instance
        .collection("guests")
        .where("eventId", isEqualTo: eventId);

    bool shownIndexHint = false;

    void applySnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot, {
      bool sortClientSide = false,
    }) {
      final docs = snapshot.docs.toList();

      if (sortClientSide) {
        docs.sort((a, b) {
          final ta = a.data()['createdAt'];
          final tb = b.data()['createdAt'];

          final da = ta is Timestamp
              ? ta.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final db = tb is Timestamp
              ? tb.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return db.compareTo(da); // desc
        });
      }

      final list =
          docs.map((d) => GuestModel.fromFirestore(d.data(), d.id)).toList();

      guests.assignAll(list);
      filteredGuests.assignAll(list);

      _rebuildGuestEmailIndex();

      currentPage.value = 0;
      _updatePagination();
      isInitialized.value = true;
    }

    // ✅ Try server-side order first (best)
    _guestSub =
        baseQuery.orderBy("createdAt", descending: true).snapshots().listen(
      (snap) => applySnapshot(snap),
      onError: (Object e, StackTrace st) {
        debugPrint('Guest query failed: $e\n$st');

        // ✅ If index missing, fall back to client-side sort (so app works immediately)
        if (e is FirebaseException && e.code == 'failed-precondition') {
          if (!shownIndexHint &&
              Get.isRegistered<SnackbarMessageController>()) {
            shownIndexHint = true;
            Get.find<SnackbarMessageController>().showInfoMessage(
              'Firestore index is required for sorting guests by createdAt. '
              'Temporary fallback enabled (client-side sorting). Create the index to remove this.',
            );
          }

          _guestSub?.cancel();
          _guestSub = baseQuery.snapshots().listen(
            (snap) => applySnapshot(snap, sortClientSide: true),
            onError: (Object e2, StackTrace st2) {
              debugPrint('Guest fallback query failed: $e2\n$st2');
              isInitialized.value = true; // stop loader
            },
          );
          return;
        }

        // ✅ Any other error: stop loader and keep empty lists
        guests.clear();
        filteredGuests.clear();
        _updatePagination();
        isInitialized.value = true;

        if (Get.isRegistered<SnackbarMessageController>()) {
          Get.find<SnackbarMessageController>().showErrorMessage(
            'Failed to load guests: ${e is FirebaseException ? (e.message ?? e.code) : e.toString()}',
          );
        }
      },
    );
  }

  // ---------------------------
  // ✅ Invitations RSVP realtime listener (MAIN + COMPANIONS)
  // ---------------------------

  void _listenInvitationsForRsvp() {
    _invitationSub?.cancel();
    if (eventId.trim().isEmpty) return;

    _invitationSub = FirebaseFirestore.instance
        .collection('invitations')
        .where('eventId', isEqualTo: eventId.trim())
        .snapshots()
        .listen((snap) {
      final map = <String, GuestRsvpStatus>{};

      void upsert({
        required String idKey,
        required bool responded,
        required bool? isAttending,
        required DateTime? updatedAt,
      }) {
        final key = idKey.trim();
        if (key.isEmpty) return;

        final prev = map[key];
        if (prev == null) {
          map[key] = GuestRsvpStatus(
            hasResponded: responded,
            isAttending: isAttending,
            updatedAt: updatedAt,
          );
          return;
        }

        final prevAt = prev.updatedAt;
        final nextAt = updatedAt;

        final bool takeNext = (prevAt == null && nextAt != null) ||
            (prevAt != null && nextAt != null && nextAt.isAfter(prevAt));

        if (takeNext) {
          map[key] = GuestRsvpStatus(
            hasResponded: prev.hasResponded || responded,
            isAttending: isAttending ?? prev.isAttending,
            updatedAt: nextAt ?? prevAt,
          );
        } else {
          // keep prev timestamp, but merge flags
          map[key] = GuestRsvpStatus(
            hasResponded: prev.hasResponded || responded,
            isAttending: prev.isAttending ?? isAttending,
            updatedAt: prevAt ?? nextAt,
          );
        }
      }

      void addPerson({
        required dynamic guestIdRaw,
        required dynamic emailLowerRaw,
        required dynamic respondedRaw,
        required dynamic isAttendingRaw,
        required dynamic updatedAtRaw,
      }) {
        final guestId = _s(guestIdRaw);
        final emailLower = _s(emailLowerRaw).toLowerCase();

        final bool? isAttending =
            (isAttendingRaw is bool) ? isAttendingRaw : null;

        final responded = respondedRaw == true || isAttending != null;

        final updatedAt = _toDate(updatedAtRaw);

        // Primary key (guestId from invitation)
        if (guestId.isNotEmpty) {
          upsert(
            idKey: guestId,
            responded: responded,
            isAttending: isAttending,
            updatedAt: updatedAt,
          );
        }

        // Fallback key: match by email to whatever your Guest row uses as key
        final fallbackKey = _guestKeyByEmailLower[emailLower];
        if (fallbackKey != null && fallbackKey.isNotEmpty) {
          upsert(
            idKey: fallbackKey,
            responded: responded,
            isAttending: isAttending,
            updatedAt: updatedAt,
          );
        }
      }

      for (final d in snap.docs) {
        final data = d.data();

        // ✅ MAIN guest
        addPerson(
          guestIdRaw: data['guestId'],
          emailLowerRaw: data['guestEmailLower'] ?? data['guestEmail'],
          respondedRaw: data['hasResponded'] ?? data['attendingSubmitted'],
          isAttendingRaw: data['isAttending'],
          updatedAtRaw: data['attendingSubmittedAt'] ??
              data['rsvpSubmittedAt'] ??
              data['modifiedAt'] ??
              data['createdAt'],
        );

        // ✅ COMPANIONS
        final comps = data['companions'];
        if (comps is List) {
          for (final c in comps) {
            if (c is! Map) continue;
            final cm = Map<String, dynamic>.from(c);

            addPerson(
              guestIdRaw: cm['guestId'],
              emailLowerRaw: cm['guestEmailLower'] ?? cm['guestEmail'],
              respondedRaw: cm['hasResponded'] ?? cm['attendingSubmitted'],
              isAttendingRaw: cm['isAttending'],
              updatedAtRaw: cm['attendingSubmittedAt'] ??
                  cm['rsvpSubmittedAt'] ??
                  cm['modifiedAt'] ??
                  cm['createdAt'],
            );
          }
        }
      }

      rsvpByGuestId.assignAll(map);
      rsvpByGuestId.refresh();
    });
  }

  // ---------------------------
  // Event meta
  // ---------------------------

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

  // ---------------------------
  // Save / update guest
  // ---------------------------

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
      await _firestoreServices.updateGuestMaxInvite(
        guestId: _currentGuestId!,
        maxGuestInvite: maxGuestInvite.value,
      );
      return true;
    } catch (e, st) {
      debugPrint('updateGuest error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateGuestMaxInviteDirectly(
      String guestDocId, int value) async {
    try {
      await _firestoreServices.updateGuestMaxInvite(
        guestId: guestDocId,
        maxGuestInvite: value,
      );
      return true;
    } catch (e, st) {
      debugPrint('updateGuestMaxInviteDirectly error: $e\n$st');
      return false;
    }
  }

  String? _currentGuestId;

  void updateAllFields(GuestModel guest) {
    _currentGuestId = guest.docId.isNotEmpty ? guest.docId : guest.guestId;

    name.text = guest.name;
    email.text = guest.email;
    address.text = guest.address ?? '';
    city.text = guest.city ?? '';

    selectedCountry.value = guest.country;
    selectedState.value = guest.state;
    selectedGender.value = guest.gender;

    isDisabled.value = guest.isDisabled;
    maxGuestInvite.value = guest.maxGuestInvite;
  }

  Future<void> deleteGuest(String guestId) async {
    await FirebaseFirestore.instance.collection("guests").doc(guestId).delete();
  }

  // ---------------------------
  // File Upload (CSV/XLSX)
  // ---------------------------

  Future<Map<String, int>> uploadGuestsFromFile(PlatformFile file) async {
    try {
      final List<GuestModel> parsedGuests;

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

      final existingEmails = guests.map((g) => g.email.toLowerCase()).toSet();

      final List<GuestModel> uniqueGuests = [];
      int skippedCount = 0;

      for (final guest in parsedGuests) {
        final emailLower = guest.email.toLowerCase();
        if (existingEmails.contains(emailLower)) {
          skippedCount++;
        } else {
          uniqueGuests.add(guest);
          existingEmails.add(emailLower);
        }
      }

      if (uniqueGuests.isEmpty) {
        return {'added': 0, 'skipped': skippedCount};
      }

      int count = 0;

      for (final guest in uniqueGuests) {
        try {
          await _firestoreServices.saveGuest(guest);
          count++;
        } catch (e) {
          debugPrint('Failed to save guest ${guest.email}: $e');
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

      final invitations = snapshot.docs
          .map((doc) {
            final g = GuestModel.fromFirestore(doc.data(), doc.id);
            if (g.email.trim().isEmpty) return null;
            return {
              'guestEmail': g.email.trim(),
              'guestId': doc.id,
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

  void filterGuests(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredGuests.assignAll(guests);
      currentPage.value = 0;
      _updatePagination();
      return;
    }

    final results = guests.where((g) {
      final nameValue = g.name.toLowerCase();
      final emailValue = g.email.toLowerCase();
      return nameValue.contains(q) || emailValue.contains(q);
    }).toList();

    filteredGuests.assignAll(results);
    currentPage.value = 0;
    _updatePagination();
  }

  void clearFilter() {
    searchController.clear();
    filteredGuests.assignAll(guests);
    currentPage.value = 0;
    _updatePagination();
  }

  // ---------------------------
  // Pagination helpers
  // ---------------------------

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

  int get totalPages {
    final total = filteredGuests.length;
    if (total == 0) return 0;
    return (total + pageSize - 1) ~/ pageSize;
  }

  void nextPage() {
    final pages = totalPages;
    if (pages == 0) return;
    if (currentPage.value < pages - 1) {
      currentPage.value++;
      _updatePagination();
    }
  }

  void prevPage() {
    if (filteredGuests.isEmpty) return;
    if (currentPage.value > 0) {
      currentPage.value--;
      _updatePagination();
    }
  }

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
