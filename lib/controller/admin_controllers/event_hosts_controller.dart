import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/host_user_row.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

class EventHostsController extends GetxController {
  final FirebaseFirestore _db;
  final String eventDocId;

  /// Required for host create + resend verification
  final String organisationId;

  EventHostsController({
    FirebaseFirestore? db,
    required this.eventDocId,
    required this.organisationId,
  }) : _db = db ?? FirebaseFirestore.instance;

  final CloudFunctionsService _cloudFns = Get.find<CloudFunctionsService>();

  final RxBool isLoading = true.obs;

  final RxList<String> hostUserIds = <String>[].obs;
  final RxnString primaryHostUserId = RxnString();

  final RxList<HostUserRow> hosts = <HostUserRow>[].obs;
  final RxString search = ''.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  int _refreshEpoch = 0;

  DocumentReference<Map<String, dynamic>> get _eventRef =>
      _db.collection('events').doc(eventDocId);

  @override
  void onInit() {
    super.onInit();
    _bindEvent();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _bindEvent() {
    _sub = _eventRef.snapshots().listen((snap) {
      final data = snap.data() ?? {};

      final idsRaw = (data['hostUserIds'] is List)
          ? (data['hostUserIds'] as List)
          : <dynamic>[];

      final ids = <String>[];
      final seen = <String>{};
      for (final x in idsRaw) {
        final s = (x ?? '').toString().trim();
        if (s.isEmpty) continue;
        if (seen.add(s)) ids.add(s);
      }
      hostUserIds.assignAll(ids);

      final primary = (data['primaryHostUserId'] ?? '').toString().trim();
      primaryHostUserId.value = primary.isEmpty ? null : primary;

      _refreshHostUsers();
    });
  }

  Future<void> _refreshHostUsers() async {
    final epoch = ++_refreshEpoch;
    isLoading.value = true;

    try {
      final ids = hostUserIds.toList();
      if (ids.isEmpty) {
        hosts.clear();
        return;
      }

      final out = <HostUserRow>[];

      // Firestore whereIn limit = 10 -> chunk
      for (int i = 0; i < ids.length; i += 10) {
        final chunk =
            ids.sublist(i, (i + 10) > ids.length ? ids.length : (i + 10));

        final qs = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final d in qs.docs) {
          out.add(HostUserRow.fromUserDoc(d));
        }
      }

      // keep only host role
      out.removeWhere((u) => u.role.trim() != 'host');

      // sort primary first
      final primary = primaryHostUserId.value;
      out.sort((a, b) {
        if (primary != null) {
          if (a.userId == primary && b.userId != primary) return -1;
          if (b.userId == primary && a.userId != primary) return 1;
        }
        return a.email.toLowerCase().compareTo(b.email.toLowerCase());
      });

      if (epoch == _refreshEpoch) {
        hosts.assignAll(out);
      }
    } finally {
      if (epoch == _refreshEpoch) {
        isLoading.value = false;
      }
    }
  }

  List<HostUserRow> get filteredHosts {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return hosts.toList();

    return hosts.where((h) {
      final name = (h.name ?? '').toLowerCase();
      final email = h.email.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  // ------------------------------------------------------------------
  // NEW FLOW:
  // 1) Add Host popup -> Create host user (NO email) -> assign to event
  // 2) Host table -> Resend verification email
  // ------------------------------------------------------------------

  /// Create host in Auth + Firestore (sendEmail=true), then assign to event.
  Future<String> createHostAndAssign({
    required String name,
    required String email,
    required String address,
    required String country,
    required bool isDisabled,
  }) async {
    final res = await _cloudFns.createHostUser(
      organisationId: organisationId,
      name: name.trim(),
      email: email.trim(),
      address: address.trim(),
      country: country.trim(),
      isDisabled: isDisabled,
      sendEmail: true, // ✅ Send password setup email on host creation
    );

    final uid = (res['uid'] ?? '').toString().trim();
    if (uid.isEmpty) {
      throw Exception('createHostUser did not return uid.');
    }

    await addHost(uid);
    return uid;
  }

  /// Send verification email (and optionally password link) from Host table.
  Future<Map<String, dynamic>> resendVerificationEmail(
    String hostUid, {
    bool sendPasswordLink = true,
  }) async {
    return _cloudFns.resendHostVerificationEmail(
      organisationId: organisationId,
      hostUid: hostUid,
      sendPasswordLink: sendPasswordLink,
    );
  }

  // ------------------------------------------------------------------
  // Event updates (host list + primary)
  // ------------------------------------------------------------------

  /// Add host to event. If no primary exists, set this as primary.
  Future<void> addHost(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;

    final updates = <String, dynamic>{
      'hostUserIds': FieldValue.arrayUnion([uid]),
      'modifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if ((primaryHostUserId.value ?? '').trim().isEmpty) {
      updates['primaryHostUserId'] = uid;
    }

    await _eventRef.update(updates);
  }

  Future<void> updateHostProfile({
    required String hostUid,
    required String name,
    required String address,
    required String country,
    required bool isDisabled,
  }) async {
    final uid = hostUid.trim();
    if (uid.isEmpty) throw Exception('Invalid host uid');

    final now = FieldValue.serverTimestamp();

    final userRef = _db.collection('users').doc(uid);
    final orgHostRef = _db
        .collection('organisations')
        .doc(organisationId)
        .collection('hosts')
        .doc(uid);

    final batch = _db.batch();

    // ✅ Update users/{uid}
    batch.set(
      userRef,
      {
        'name': name.trim(),
        'address': address.trim(),
        'country': country.trim(),
        'isDisabled': isDisabled,
        'modifiedAt': now,
      },
      SetOptions(merge: true),
    );

    // ✅ Update organisations/{orgId}/hosts/{uid}
    batch.set(
      orgHostRef,
      {
        'name': name.trim(),
        'address': address.trim(),
        'country': country.trim(),
        'isDisabled': isDisabled,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // ✅ Refresh list (event doc won't change, so we must refresh manually)
    await _refreshHostUsers();
  }

  /// Remove host from event. If removing primary, choose a new primary.
  Future<void> removeHost(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;

    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && me == uid) {
      throw Exception("You can't remove yourself from this event.");
    }

    final currentHosts = hostUserIds.toList();
    if (!currentHosts.contains(uid)) return;

    if (currentHosts.length <= 1) {
      throw Exception("At least one host must remain for the event.");
    }

    final newHosts = currentHosts.where((x) => x != uid).toList();

    final currentPrimary = primaryHostUserId.value;
    String? newPrimary = currentPrimary;

    if (currentPrimary != null && currentPrimary == uid) {
      newPrimary = newHosts.isNotEmpty ? newHosts.first : null;
    }

    await _eventRef.update({
      'hostUserIds': newHosts,
      'primaryHostUserId': newPrimary,
      'modifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _refreshHostUsers();
  }

  /// Set primary host (any host/admin can do this per your dev-friendly rules).
  Future<void> setPrimary(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;

    await _eventRef.update({
      'primaryHostUserId': uid,
      'hostUserIds': FieldValue.arrayUnion([uid]),
      'modifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
