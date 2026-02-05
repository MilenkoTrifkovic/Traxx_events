import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/menu_category_helper.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

class OrganisationController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();

  final organisation = Rxn<Organisation>();
  final RxBool isInitialized = false.obs;
  final RxBool isLoading = false.obs;

  final String organisationId;
  final RxBool showMenuItemPrices = true.obs;

  StreamSubscription<DocumentSnapshot<Organisation>>? _orgSub;
  DocumentReference<Organisation>? _orgRef;

  String? _lastLogoPath;
  String? _lastLogoUrl;

  OrganisationController(this.organisationId);

  @override
  void onInit() {
    super.onInit();
    final id = organisationId.trim();
    if (id.isNotEmpty) {
      _bindOrganisationRealtime(id);
    } else {
      isInitialized.value = true;
    }
  }

  @override
  void onClose() {
    _orgSub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // ✅ REALTIME BIND (works for both docId schema + legacy schema)
  // ---------------------------------------------------------------------------
  Future<void> _bindOrganisationRealtime(String orgId) async {
    isLoading.value = true;

    try {
      // ✅ Resolve correct organisation doc ref (docId == orgId OR query by field)
      _orgRef = await _resolveOrganisationRef(orgId);

      // ✅ Load once immediately (so UI gets data right away)
      final initial = await _orgRef!.get();
      if (initial.exists && initial.data() != null) {
        await _applyOrganisation(initial.data()!);
      }

      // ✅ Listen realtime
      await _orgSub?.cancel();
      _orgSub = _orgRef!.snapshots().listen((snap) async {
        if (!snap.exists || snap.data() == null) {
          isInitialized.value = true;
          isLoading.value = false;
          return;
        }

        await _applyOrganisation(snap.data()!);

        isInitialized.value = true;
        isLoading.value = false;
      }, onError: (e) {
        print('Org stream error: $e');
        isInitialized.value = true;
        isLoading.value = false;
      });

      isInitialized.value = true;
    } catch (e) {
      print('❌ Failed to bind organisation realtime: $e');
      isInitialized.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Resolves organisation doc reference:
  /// 1) Try docId == orgId
  /// 2) Fallback: where('organisationId' == orgId)
  Future<DocumentReference<Organisation>> _resolveOrganisationRef(
      String orgId) async {
    // 1) docId path
    final direct = _firestoreServices.organisationsRef.doc(orgId);
    final byDoc = await direct.get();
    if (byDoc.exists) {
      // print('✅ Org resolved by docId: $orgId');
      return direct;
    }

    // 2) legacy field path
    final q = await _firestoreServices.organisationsRef
        .where('organisationId', isEqualTo: orgId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Organisation not found for organisationId=$orgId');
    }

    // print('✅ Org resolved by field organisationId=$orgId docId=${q.docs.first.id}');
    return q.docs.first.reference;
  }

  /// Apply org, update toggle + load logo URL only when changed.
  // Apply org, update toggle + load logo URL only when changed.
// ✅ Also keeps Guest-public org settings in sync using the PUBLIC org id
//    (the same id stored in events.organisationId)
  Future<void> _applyOrganisation(Organisation org) async {
    // 1) update reactive flag
    showMenuItemPrices.value = org.showMenuItemPrices ?? true;

    // 2) ✅ Sync guest-public settings doc using PUBLIC org id
    // Prefer org.organisationId (stored inside the org document), fallback to controller orgId.
    final publicOrgId = organisationId.trim();

    if (publicOrgId.isNotEmpty) {
      // fire-and-forget is fine here; do not block UI on this
      FirebaseFirestore.instance
          .collection('orgPublicSettings')
          .doc(publicOrgId)
          .set(
        {
          'showMenuItemPrices': showMenuItemPrices.value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // Optional legacy compatibility (ONLY if you want)
    // Keeps old docId-based public doc in sync too.
    if (_orgRef != null) {
      FirebaseFirestore.instance
          .collection('orgPublicSettings')
          .doc(_orgRef!.id)
          .set(
        {
          'showMenuItemPrices': showMenuItemPrices.value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // 3) logo loading (unchanged logic)
    final logoPath = (org.logo ?? '').trim();

    if (logoPath.isEmpty) {
      organisation.value = org;
      _lastLogoPath = null;
      _lastLogoUrl = null;
      return;
    }

    // If same logo already loaded, reuse cached URL
    if (_lastLogoPath == logoPath && (_lastLogoUrl ?? '').isNotEmpty) {
      organisation.value = org.copyWith(photoUrl: _lastLogoUrl);
      return;
    }

    try {
      final storage = Get.find<StorageServices>();
      final url = await storage.loadImageURL(logoPath);
      _lastLogoPath = logoPath;
      _lastLogoUrl = url;
      organisation.value = org.copyWith(photoUrl: url);
    } catch (e) {
      print('Failed to load organisation image: $e');
      _lastLogoPath = logoPath;
      _lastLogoUrl = null;
      organisation.value = org;
    }
  }

  // ---------------------------------------------------------------------------
  // Keep your old method if some screens still call it directly
  // ---------------------------------------------------------------------------
  Future<void> loadOrganisation(String organisationId) async {
    try {
      isLoading.value = true;

      final id = organisationId.trim();
      if (id.isEmpty) {
        isInitialized.value = true;
        return;
      }

      final org = await _firestoreServices.getOrganisation(id);

      // also resolve ref so updates work even in legacy schema
      _orgRef ??= await _resolveOrganisationRef(id);

      await _applyOrganisation(org);
      isInitialized.value = true;
    } catch (e) {
      print('Error loading organisation: $e');
      isInitialized.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ Update toggle (legacy-safe)
  // ---------------------------------------------------------------------------

  Future<void> updateShowMenuItemPrices(bool v) async {
    final publicOrgId =
        organisationId.trim(); // ✅ THIS must match event.organisationId
    if (publicOrgId.isEmpty) return;

    isLoading.value = true;
    try {
      _orgRef ??= await _resolveOrganisationRef(publicOrgId);

      // 1) update org doc
      await _orgRef!.update({
        'showMenuItemPrices': v,
        'modifiedDate': FieldValue.serverTimestamp(),
      });

      // 2) update guest-public doc (this is what guest listens to)
      await FirebaseFirestore.instance
          .collection('orgPublicSettings')
          .doc(publicOrgId)
          .set(
        {
          'showMenuItemPrices': v,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Optional: also keep legacy docId version in sync
      if (_orgRef!.id != publicOrgId) {
        await FirebaseFirestore.instance
            .collection('orgPublicSettings')
            .doc(_orgRef!.id)
            .set(
          {
            'showMenuItemPrices': v,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // optimistic UI
      showMenuItemPrices.value = v;
      final current = organisation.value;
      if (current != null)
        organisation.value = current.copyWith(showMenuItemPrices: v);
    } catch (e) {
      print('Failed to update showMenuItemPrices: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Organisation? getOrganisation() => organisation.value;

  String getOrganisationName() => organisation.value?.name ?? 'Event Manager';

  String? getOrganisationPhotoUrl() => organisation.value?.photoUrl;

  DocumentReference<Map<String, dynamic>> _rawOrgRef() {
    return FirebaseFirestore.instance
        .collection('organisations')
        .doc(_orgRef!.id);
  }

  void setOrganisation(Organisation org) {
    organisation.value = org;
    showMenuItemPrices.value = org.showMenuItemPrices ?? true;
  }

  Future<bool> updateOrganisation(Organisation org) async {
    try {
      final updated = await _firestoreServices.updateOrganisation(org);
      organisation.value = updated;
      showMenuItemPrices.value = updated.showMenuItemPrices ?? true;
      return true;
    } catch (e) {
      print('Error updating organisation: $e');
      return false;
    }
  }

  void clearOrganisation() {
    organisation.value = null;
    _lastLogoPath = null;
    _lastLogoUrl = null;
  }

  // ---------------------------------------------------------------------------
  // ✅ Custom category write (legacy-safe)
  // ---------------------------------------------------------------------------
  Future<void> ensureCustomCategoryExists(String category) async {
    final c = MenuCategoryHelper.formatCategoryName(category);
    if (c.trim().isEmpty) return;

    if (MenuCategoryHelper.isEnumCategory(c)) return;

    final id = organisationId.trim();
    if (id.isEmpty) return;

    final org = organisation.value;
    final existing = (org?.customMenuCategories ?? []);
    final exists =
        existing.any((x) => x.trim().toLowerCase() == c.toLowerCase());
    if (exists) return;

    // optimistic local update
    if (org != null) {
      organisation.value = org.copyWith(customMenuCategories: [...existing, c]);
    }

    try {
      _orgRef ??= await _resolveOrganisationRef(id);
      await _rawOrgRef().set(
        {
          'customMenuCategories': FieldValue.arrayUnion([c]),
          'modifiedDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Failed to ensure custom category: $e');
    }
  }
}
