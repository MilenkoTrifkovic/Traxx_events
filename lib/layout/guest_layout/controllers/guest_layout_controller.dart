import 'package:cloud_firestore/cloud_firestore.dart';
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
    print(
        '🎫 loadEventCoverImageFromInvitation called with invitationId: $invitationId');

    // Skip if invitationId is null/empty
    if (invitationId == null || invitationId.isEmpty) {
      print('⚠️ No invitationId provided');
      return;
    }

    // Skip if we're already loading this invitation
    if (_currentInvitationId == invitationId &&
        eventCoverImageUrl.value != null) {
      print('✅ Already loaded image for invitation: $invitationId');
      return;
    }

    // Skip if already loading
    if (isLoadingImage.value) {
      print('⏳ Already loading image, skipping...');
      return;
    }

    _currentInvitationId = invitationId;
    isLoadingImage.value = true;
    error.value = null;

    try {
      // 1. Fetch invitation document
      print('📥 Fetching invitation: $invitationId');
      final invitationDoc =
          await _invitationServices.getInvitation(invitationId);

      if (!invitationDoc.exists || invitationDoc.data() == null) {
        print('❌ Invitation not found: $invitationId');
        eventCoverImageUrl.value = null;
        return;
      }

      // 2. Extract eventId from invitation
      final eventId = invitationDoc.data()?['eventId'] as String?;

      if (eventId == null || eventId.isEmpty) {
        print('❌ No eventId in invitation');
        eventCoverImageUrl.value = null;
        return;
      }

      print('✅ Found eventId: $eventId');

      // 3. Load event cover image using eventId
      await loadEventCoverImage(eventId);
    } catch (e) {
      error.value = 'Failed to load event cover image';
      print('❌ Error loading event cover image from invitation: $e');
      eventCoverImageUrl.value = null;
    } finally {
      isLoadingImage.value = false;
    }
  }

  Future<void> _loadVenuePhotosFromEvent(Event eventData) async {
    try {
      isLoadingVenuePhotos.value = true;

      // ✅ Find venueId from event
      final m = eventData.toJson();
      final venueId = (m['venueId'] ??
              m['venueID'] ??
              m['selectedVenueId'] ??
              m['selectedVenueID'])
          ?.toString()
          .trim();

      if (venueId == null || venueId.isEmpty) {
        venuePhotoUrls.clear();
        _currentVenueId = null;
        return;
      }

      // cache guard
      if (_currentVenueId == venueId && venuePhotoUrls.isNotEmpty) return;
      _currentVenueId = venueId;

      // ✅ Fetch venue doc by venueID field
      final qs = await FirebaseFirestore.instance
          .collection('venues')
          .where('venueID', isEqualTo: venueId)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        venuePhotoUrls.clear();
        return;
      }

      final data = qs.docs.first.data();

      // ✅ Your schema: photoPaths (List) + photoPath (String)
      final dynamic rawList = data['photoPaths'];
      final dynamic rawSingle = data['photoPath'];

      // Build a single list of storage paths/urls
      final List<String> paths = <String>[];

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
        venuePhotoUrls.clear();
        return;
      }

      // ✅ Convert storage paths to download URLs (keep http urls as-is)
      final futures = paths.map((p) async {
        if (p.startsWith('http://') || p.startsWith('https://')) return p;
        final url = await _storageServices.loadImageURL(p);
        return (url ?? '').trim();
      }).toList();

      final urls =
          (await Future.wait(futures)).where((u) => u.isNotEmpty).toList();
      venuePhotoUrls.assignAll(urls);
    } catch (e) {
      print('❌ Error loading venue photos: $e');
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
    print('📸 loadEventCoverImage called with eventId: $eventId');

    if (eventId == null || eventId.isEmpty) return;

    if (_currentEventId == eventId && event.value != null) {
      print('✅ Already loaded event: $eventId');
      return;
    }

    _currentEventId = eventId;
    isLoadingImage.value = true;
    error.value = null;

    try {
      print('📥 Fetching event data from Firestore...');
      final eventData = await _firestoreServices.getEventById(eventId);

      event.value = eventData;
      print('✅ Event data loaded: ${eventData.name}');

      // ✅ Load venue photos (non-blocking, but awaited to keep consistent state)
      await _loadVenuePhotosFromEvent(eventData);

      if (eventData.coverImageUrl == null || eventData.coverImageUrl!.isEmpty) {
        print('ℹ️ Event $eventId has no cover image');
        eventCoverImageUrl.value = null;
        return;
      }

      print('📥 Loading cover image from Storage...');
      final downloadUrl =
          await _storageServices.loadImageURL(eventData.coverImageUrl);

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        eventCoverImageUrl.value = downloadUrl;
        print('✅ Event cover image loaded: $downloadUrl');
      } else {
        print('⚠️ Could not load download URL for event cover image');
        eventCoverImageUrl.value = null;
      }
    } catch (e) {
      error.value = 'Failed to load event data';
      print('❌ Error loading event: $e');
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
