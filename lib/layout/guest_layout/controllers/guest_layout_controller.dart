import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/firestore_services/invitation_response_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

/// Controller for guest layout wrapper
/// Manages event data fetching and caching for guest pages
/// Provides single source of truth for event information across guest flow
class GuestLayoutController extends GetxController {
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final StorageServices _storageServices = Get.find<StorageServices>();
  final InvitationResponseServices _invitationServices =
      InvitationResponseServices();

  // Reactive variables
  final Rx<Event?> event = Rx<Event?>(null); // Full event object
  final Rx<String?> eventCoverImageUrl = Rx<String?>(null);
  final RxBool isLoadingImage = false.obs;
  final Rx<String?> error = Rx<String?>(null);

  final RxList<String> venuePhotoUrls = <String>[].obs;
  final RxBool isLoadingVenuePhotos = false.obs;

  String? _currentVenueId;
  String? _currentEventId;
  String? _currentInvitationId;
  String? lastLoadedInvitationId;

  // Convenience getters for child widgets (RsvpResponsePage, etc.)
  String? get eventName => event.value?.name;
  String? get eventId => event.value?.eventId;
  String? get eventDescription => event.value?.description;
  DateTime? get eventDate => event.value?.date;
  String? get eventAddress => event.value?.address;
  String? get eventType => event.value?.eventType;
  DateTime? get rsvpDeadline => event.value?.rsvpDeadline;
  bool get hasEvent => event.value != null;

  /// Load event cover image from invitation ID
  /// Fetches invitation document, extracts eventId, then loads event cover image
  /// This is the primary method used by GuestPageWrapper
  Future<void> loadEventCoverImageFromInvitation(String? invitationId) async {
    debugPrint('🎫 loadEventCoverImageFromInvitation: $invitationId');

    if (invitationId == null || invitationId.isEmpty) return;

    // ✅ Only skip if BOTH cover + venue photos are already loaded
    if (_currentInvitationId == invitationId &&
        event.value != null &&
        (eventCoverImageUrl.value ?? '').isNotEmpty &&
        venuePhotoUrls.isNotEmpty) {
      debugPrint(
          '✅ Already loaded cover + venue photos for invitation: $invitationId');
      return;
    }

    // ✅ allow retry if venue photos are missing
    if (isLoadingImage.value) return;

    _currentInvitationId = invitationId;
    isLoadingImage.value = true;
    error.value = null;

    try {
      final invitationDoc =
          await _invitationServices.getInvitation(invitationId);
      if (!invitationDoc.exists || invitationDoc.data() == null) {
        debugPrint('❌ Invitation not found: $invitationId');
        return;
      }

      final eventId = (invitationDoc.data()?['eventId'] as String?)?.trim();
      if (eventId == null || eventId.isEmpty) {
        debugPrint('❌ No eventId in invitation');
        return;
      }

      await loadEventCoverImage(eventId);
    } catch (e, st) {
      debugPrint('❌ loadEventCoverImageFromInvitation error: $e\n$st');
      error.value = 'Failed to load event';
    } finally {
      isLoadingImage.value = false;
    }
  }

  Future<void> _loadVenuePhotosFromEvent(Event eventData) async {
    debugPrint('🏛️ eventData.venueId = "${eventData.venueId}"');
    try {
      isLoadingVenuePhotos.value = true;

      // ✅ Prefer the typed field if you have it
      final venueId = (eventData.venueId ?? '').toString().trim();
      debugPrint('🏛️ eventData.venueId = "$venueId"');

      if (venueId.isEmpty) {
        venuePhotoUrls.clear();
        _currentVenueId = null;
        return;
      }

      // Cache guard
      if (_currentVenueId == venueId && venuePhotoUrls.isNotEmpty) return;
      _currentVenueId = venueId;

      Map<String, dynamic>? venueData;

      // ✅ 1) Try direct doc lookup (when event stores venue docId)
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .get();

      if (doc.exists && doc.data() != null) {
        venueData = doc.data()!;
        debugPrint('✅ Venue found by DOC ID: $venueId');
      }

      debugPrint('🏛️ venueData found? ${venueData != null}');

      // ✅ 2) Fallback: query by venueID field (when event stores venueID)
      if (venueData == null) {
        final qs = await FirebaseFirestore.instance
            .collection('venues')
            .where('venueID', isEqualTo: venueId)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) venueData = qs.docs.first.data();
        if (qs.docs.isNotEmpty) {
          venueData = qs.docs.first.data();
          debugPrint('✅ Venue found by venueID field: $venueId');
        }
      }

      // ✅ 3) Extra fallback: some schemas use `venueId` field
      if (venueData == null) {
        final qs = await FirebaseFirestore.instance
            .collection('venues')
            .where('venueId', isEqualTo: venueId)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) {
          venueData = qs.docs.first.data();
          debugPrint('✅ Venue found by venueId field: $venueId');
        }
      }

      if (venueData == null) {
        debugPrint('❌ Venue NOT found for venueId="$venueId"');
        venuePhotoUrls.clear();
        venuePhotoUrls.refresh();
        return;
      }
      debugPrint('✅ venue photoPaths = ${venueData['photoPaths']}');

      final rawList = venueData['photoPaths']; // List<String>
      final rawSingle = venueData['photoPath']; // String

      debugPrint('🖼️ photoPaths raw = $rawList');
      debugPrint('🖼️ photoPath raw  = $rawSingle');

      final List<String> paths = [];

      if (rawList is List) {
        paths.addAll(
          rawList.map((e) => e.toString().trim()).where((s) => s.isNotEmpty),
        );
      }

      if (paths.isEmpty && rawSingle != null) {
        final s = rawSingle.toString().trim();
        if (s.isNotEmpty) paths.add(s);
      }

      if (paths.isEmpty) {
        debugPrint('⚠️ Venue has NO photo paths');
        venuePhotoUrls.clear();
        venuePhotoUrls.refresh();
        return;
      }

      // Convert storage paths → download URLs
      final urls = await Future.wait(paths.map((p) async {
        final x = p.trim();
        if (x.startsWith('http://') || x.startsWith('https://')) return x;

        final u = await _storageServices.loadImageURL(x);
        return (u ?? '').trim();
      }));

      final cleaned = urls.where((u) => u.isNotEmpty).toList();
      debugPrint('✅ Venue photo URLs resolved: ${cleaned.length}');

      venuePhotoUrls.assignAll(cleaned);
      venuePhotoUrls.refresh();
    } catch (e) {
      debugPrint('❌ Error loading venue photos: $e');
      venuePhotoUrls.clear();
    } finally {
      isLoadingVenuePhotos.value = false;
    }
  }

  /// Load event cover image by event ID
  /// Fetches full event object and caches it
  /// Also loads the cover image download URL from Storage
  /// Used internally by loadEventCoverImageFromInvitation
  Future<void> loadEventCoverImage(String? eventId) async {
    debugPrint('📸 loadEventCoverImage: $eventId');

    if (eventId == null || eventId.isEmpty) return;

    // ✅ Cached event: still make sure venue photos are loaded
    if (_currentEventId == eventId && event.value != null) {
      if (venuePhotoUrls.isEmpty && !isLoadingVenuePhotos.value) {
        await _loadVenuePhotosFromEvent(event.value!);
        venuePhotoUrls.refresh();
      }
      return;
    }

    _currentEventId = eventId;
    isLoadingImage.value = true;
    error.value = null;

    try {
      final eventData = await _firestoreServices.getEventById(eventId);
      event.value = eventData;

      // ✅ Always load venue photos
      await _loadVenuePhotosFromEvent(eventData);
      venuePhotoUrls.refresh();

      // ✅ Cover image resolve (optional, even if you don’t show it here)
      final rawCoverPath = (eventData.coverImageUrl ?? '').trim();
      if (rawCoverPath.isEmpty) {
        eventCoverImageUrl.value = null;
        event.value = event.value?.copyWith(coverImageDownloadUrl: null);
        return;
      }

      if (rawCoverPath.startsWith('http://') ||
          rawCoverPath.startsWith('https://')) {
        eventCoverImageUrl.value = rawCoverPath;
        event.value =
            event.value?.copyWith(coverImageDownloadUrl: rawCoverPath);
        return;
      }

      final downloadUrl = await _storageServices.loadImageURL(rawCoverPath);
      final cleaned = (downloadUrl ?? '').trim();

      eventCoverImageUrl.value = cleaned.isEmpty ? null : cleaned;
      event.value = event.value?.copyWith(
        coverImageDownloadUrl: cleaned.isEmpty ? null : cleaned,
      );
    } catch (e, st) {
      debugPrint('❌ loadEventCoverImage error: $e\n$st');
      error.value = 'Failed to load event data';
      event.value = null;
      eventCoverImageUrl.value = null;
      venuePhotoUrls.clear();
    } finally {
      isLoadingImage.value = false;
    }
  }

  /// Clear cached data (useful when navigating away from guest flow)
  void clearCache() {
    event.value = null;
    eventCoverImageUrl.value = null;
    _currentEventId = null;
    _currentInvitationId = null;
    error.value = null;
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}
