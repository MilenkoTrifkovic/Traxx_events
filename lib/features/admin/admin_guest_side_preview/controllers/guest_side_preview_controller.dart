import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';

/// Controller for guest side preview page
/// Manages event data loading and step selection
class GuestSidePreviewController extends GetxController {
  final FirestoreServices _firestoreService = FirestoreServices();
  final StorageServices _storageService = StorageServices();

  final RxBool isLoading = true.obs;
  final Rx<Event?> event = Rx<Event?>(null);
  final RxString eventCoverImageUrl = RxString('');
  final RxString selectedStep = 'rsvp'.obs;
  final RxInt companionCount = 0.obs; // For preview purposes

  String? eventId;

  /// Available preview steps
  final List<PreviewStep> availableSteps = [
    PreviewStep(id: 'rsvp', label: 'RSVP Response', order: 1),
    PreviewStep(id: 'guest_count', label: 'Guest Count Selection', order: 2),
  ];

  @override
  void onInit() {
    super.onInit();
  }

  /// Load event data and cover image
  Future<void> loadEvent(String eventId) async {
    this.eventId = eventId;
    isLoading.value = true;

    try {
      // Load event from Firestore
      final eventData = await _firestoreService.getEventById(eventId);
      event.value = eventData;

      // Load cover image if available
      if (eventData.coverImageUrl != null && eventData.coverImageUrl!.isNotEmpty) {
        try {
          final imageUrl = await _storageService.loadImageURL(eventData.coverImageUrl!);
          eventCoverImageUrl.value = imageUrl ?? '';
        } catch (e) {
          debugPrint('⚠️ Failed to load cover image: $e');
          eventCoverImageUrl.value = '';
        }
      }

      // Update available steps based on event configuration
      _updateAvailableSteps(eventData);
    } catch (e) {
      debugPrint('❌ Error loading event: $e');
      event.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update available steps based on event configuration
  void _updateAvailableSteps(Event eventData) {
    // RSVP, Guest Count, and Companions Info steps are available
    // Other steps will be added later
    availableSteps.clear();
    availableSteps.add(PreviewStep(id: 'rsvp', label: 'RSVP Response', order: 1));
    availableSteps.add(PreviewStep(id: 'guest_count', label: 'Guest Count Selection', order: 2));
    availableSteps.add(PreviewStep(id: 'companions_info', label: 'Companions Information', order: 3));
    
    // Add demographics step if question set is configured
    if (eventData.selectedDemographicQuestionSetId != null && 
        eventData.selectedDemographicQuestionSetId!.isNotEmpty) {
      availableSteps.add(PreviewStep(id: 'demographics', label: 'Demographics', order: 4));
    }

    // Add menu step if menu items are configured
    if (eventData.selectedMenuItemIds != null && 
        eventData.selectedMenuItemIds!.isNotEmpty) {
      availableSteps.add(PreviewStep(id: 'menu', label: 'Menu Selection', order: 5));
    }
  }

  /// Set selected step
  void setSelectedStep(String stepId) {
    selectedStep.value = stepId;
  }

  /// Get step by ID
  PreviewStep? getStepById(String stepId) {
    try {
      return availableSteps.firstWhere((step) => step.id == stepId);
    } catch (e) {
      return null;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}

/// Preview step model
class PreviewStep {
  final String id;
  final String label;
  final int order;

  PreviewStep({
    required this.id,
    required this.label,
    required this.order,
  });
}

