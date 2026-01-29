import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'dart:async';

class AuthController extends GetxController {
  late final FirestoreServices _firestoreServices;
  late final SharedPrefServices _sharedPrefServices;
  late final CloudFunctionsService _cloudFunctionsService;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  final RxBool _isAuthenticated = false.obs;
  final RxBool _companyInfoExists = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;
  bool get companyInfoExists => _companyInfoExists.value;

  String? organisationId;
  final userName = 'User'.obs;
  final isLoading = true.obs;
  final userRole = Rx<UserRole?>(null);
  final organisation = Rxn<Organisation>();

  StreamSubscription<User?>? _authSub;

  /// Incremented on each auth change to invalidate in-flight async work.
  int _op = 0;

  final routerRefresh = 0.obs;

  void _bumpRouter() => routerRefresh.value++;

  AuthController()
      : _sharedPrefServices = Get.find<SharedPrefServices>(),
        _firestoreServices = Get.find<FirestoreServices>(),
        _cloudFunctionsService = Get.find<CloudFunctionsService>();

  @override
  void onInit() {
    super.onInit();

    isLoading.value = true;

    _authSub = firebaseAuth.authStateChanges().listen((user) async {
      // invalidate any in-flight profile loads
      _op++;
      final opAtStart = _op;

      isLoading.value = true;

      if (user == null) {
        // signed out
        clearSessionLocal(keepAuth: false, keepLoading: false);
        _bumpRouter();
        return;
      }

      // signed in
      _isAuthenticated.value = true;

      // IMPORTANT: clear old user's in-memory session immediately
      clearSessionLocal(keepAuth: true, keepLoading: true);

      await loadUserProfile(expectedUid: user.uid, op: opAtStart);

      // if auth changed again while we were loading, ignore finishing state
      if (opAtStart != _op) return;

      isLoading.value = false;
      _bumpRouter();
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _authSub = null;
    super.onClose();
  }

  // ─────────────────────────────────────────────
  // Session clearing
  // ─────────────────────────────────────────────

  /// Clears ALL in-memory fields that could leak previous user's session into UI.
  /// Use keepAuth=true when switching users (so auth state stays true while loading).
  /// Use keepLoading=true when you want to keep the loader visible.
  void clearSessionLocal({bool keepAuth = false, bool keepLoading = false}) {
    organisationId = null;
    userRole.value = null;
    organisation.value = null;

    _companyInfoExists.value = false; // ✅ critical for your router redirects
    userName.value = 'User';

    if (!keepAuth) {
      _isAuthenticated.value = false;
    }

    if (!keepLoading) {
      isLoading.value = false;
    }
  }

  void setOrganisationInfoExists(bool value) =>
      _companyInfoExists.value = value;
  void setAuthenticated(bool value) => _isAuthenticated.value = value;

  /// Set organisation ID after it's created (e.g., after submitting org info form).
  /// Also triggers router refresh so shell routes can react.
  void setOrganisationId(String? orgId) {
    organisationId = orgId;
    if (orgId != null && orgId.isNotEmpty) {
      _companyInfoExists.value = true;
    }
    isLoading.value = false;
    _bumpRouter();
  }

  // ─────────────────────────────────────────────
  // Auth helpers
  // ─────────────────────────────────────────────

  bool get isAuthenticatedAndVerified {
    final currentUser = firebaseAuth.currentUser;
    return currentUser != null && currentUser.emailVerified;
  }

  bool get isVerified =>
      firebaseAuth.currentUser != null &&
      firebaseAuth.currentUser!.emailVerified;

  // ─────────────────────────────────────────────
  // Organisation fetch
  // ─────────────────────────────────────────────

  Future<void> fetchOrganisation() async {
    if (organisationId == null || organisationId!.isEmpty) {
      organisation.value = null;
      return;
    }

    try {
      final org = await _firestoreServices.getOrganisation(organisationId!);
      organisation.value = org;
    } catch (_) {
      organisation.value = null;
    }
  }

  // ─────────────────────────────────────────────
  // Prefer org from Firestore users/{uid}, fallback cloud fn
  // ─────────────────────────────────────────────

  Future<void> checkOrganisationForCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      _companyInfoExists.value = false;
      organisationId = null;
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final orgIdFromUser = data?['organisationId'] as String?;

    if (orgIdFromUser != null && orgIdFromUser.isNotEmpty) {
      organisationId = orgIdFromUser;
      _companyInfoExists.value = true;
      return;
    }

    final response = await _cloudFunctionsService.checkOrganisationInfo();
    _companyInfoExists.value = response.hasOrganisation;
    organisationId = response.organisationId;
  }

  // ─────────────────────────────────────────────
  // Load user profile (stale-protected)
  // ─────────────────────────────────────────────

  Future<void> loadUserProfile({String? expectedUid, int? op}) async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return;

    final uid = expectedUid ?? currentUser.uid;
    final opAtStart = op ?? _op;

    isLoading.value = true;

    // Clear old data (but keep auth/loading)
    clearSessionLocal(keepAuth: true, keepLoading: true);

    // stale guards
    if (firebaseAuth.currentUser?.uid != uid) return;
    if (opAtStart != _op) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();

    // stale guards after await
    if (firebaseAuth.currentUser?.uid != uid) return;
    if (opAtStart != _op) return;

    if (!userDoc.exists) {
      userRole.value = UserRole.guest;
      organisationId = null;
      _companyInfoExists.value = false;
      organisation.value = null;
      return;
    }

    final data = userDoc.data() ?? {};
    final roleString = (data['role'] as String? ?? 'guest').trim();

    userRole.value = UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.guest,
    );

    // -----------------------------
    // ✅ Legacy-safe organisationId
    // -----------------------------
    String? orgId = (data['organisationId'] as String?)?.trim();
    if (orgId != null && orgId.isEmpty) orgId = null;

    // ✅ If missing in users/{uid}, fallback to roles via Cloud Function
    if (orgId == null) {
      try {
        final resp = await _cloudFunctionsService.checkOrganisationInfo();

        // stale guards after await
        if (firebaseAuth.currentUser?.uid != uid) return;
        if (opAtStart != _op) return;

        final fallbackOrgId = (resp.organisationId ?? '').trim();
        final fallbackRole = (resp.role ?? '').trim();

        if (resp.hasOrganisation && fallbackOrgId.isNotEmpty) {
          orgId = fallbackOrgId;

          // Optionally update local role from backend (admin/host)
          if (fallbackRole.isNotEmpty) {
            userRole.value = UserRole.values.firstWhere(
              (e) => e.name == fallbackRole,
              orElse: () => userRole.value ?? UserRole.guest,
            );
          }

          // ✅ Patch users/{uid} so next login/refresh is correct instantly
          await userRef.set({
            'organisationId': orgId,
            if (fallbackRole.isNotEmpty) 'role': fallbackRole,
            'modifiedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        // ignore, keep orgId null
        // print('checkOrganisationInfo fallback failed: $e');
      }
    }

    organisationId = orgId;

    // ✅ what your router reads
    _companyInfoExists.value = orgId != null && orgId.isNotEmpty;

    // Load organisation details if exists
    if (orgId != null && orgId.isNotEmpty) {
      try {
        final org = await _firestoreServices.getOrganisation(orgId);

        // stale guards after await
        if (firebaseAuth.currentUser?.uid != uid) return;
        if (opAtStart != _op) return;

        organisation.value = org;
      } catch (_) {
        organisation.value = null;
      }
    } else {
      organisation.value = null;
    }
  }

  // ─────────────────────────────────────────────
  // Logout (full cleanup)
  // ─────────────────────────────────────────────

  Future<void> logout() async {
    // Immediately clear UI so old session never stays visible
    clearSessionLocal(keepAuth: false, keepLoading: true);

    // Clear session prefs (only session keys)
    try {
      await _sharedPrefServices.clearSession();
    } catch (_) {}

    // Invalidate any in-flight loads
    _op++;

    await firebaseAuth.signOut();

    isLoading.value = false;
    _bumpRouter();
  }
}
