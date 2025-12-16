import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/snack_bar_message.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/services/image_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';

/// Controller for managing create event form state and validation
class CreateEventController extends GetxController {
  // Dependencies
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();
  final ImageServices _imageServices = ImageServices();
  final StorageServices _storageServices = StorageServices();
  final EventListController eventListController =
      Get.find<EventListController>();

  // Form field controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dressCodeController = TextEditingController();
  final TextEditingController plannerEmailController = TextEditingController();
  final TextEditingController specialNotesController = TextEditingController();

  // Observable form state
  final Rx<String?> selectedEventType = Rx<String?>(null);
  final Rx<String?> selectedVenue = Rx<String?>(null);
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> selectedStartTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> selectedEndTime = Rx<TimeOfDay?>(null);
  final Rx<DateTime?> selectedRsvpDeadline = Rx<DateTime?>(null);
  final Rx<ServiceType?> selectedServiceType = Rx<ServiceType?>(null);

  // Service Type error
  final RxString serviceTypeError = ''.obs;
  final RxBool hideHostInfo = false.obs;
  final RxBool isLoading = false.obs;

  // Cover image state
  final Rx<XFile?> selectedCoverImage = Rx<XFile?>(null);
  final RxString coverImageError = ''.obs;

  // Snackbar message state
  final Rx<SnackBarMessage?> snackBarMessage = Rx<SnackBarMessage?>(null);

  // Global snackbar helper
  final SnackbarMessageController snackbar =
      Get.find<SnackbarMessageController>();

  // Navigation state
  final RxBool shouldPop = false.obs;

  // Validation state
  final RxString nameError = ''.obs;
  final RxString eventTypeError = ''.obs;
  final RxString venueError = ''.obs;
  final RxString dateError = ''.obs;
  final RxString startTimeError = ''.obs;
  final RxString endTimeError = ''.obs;
  final RxString rsvpDeadlineError = ''.obs;
  final RxString capacityError = ''.obs;

  @override
  void onClose() {
    // Dispose controllers
    nameController.dispose();
    capacityController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    dressCodeController.dispose();
    plannerEmailController.dispose();
    specialNotesController.dispose();
    super.onClose();
  }

  /// Clear all validation errors
  void clearErrors() {
    nameError.value = '';
    eventTypeError.value = '';
    dateError.value = '';
    startTimeError.value = '';
    endTimeError.value = '';
    rsvpDeadlineError.value = '';
    capacityError.value = '';
    serviceTypeError.value = '';
    venueError.value = '';
  }

  /// Validate step 1 - Event Name, Event Type, Date, RSVP Date, Start Time, End Time
  bool validateStep1() {
    clearErrors();
    bool isValid = true;

    // Validate event name
    if (nameController.text.trim().isEmpty) {
      nameError.value = 'Event name is required';
      isValid = false;
    }

    // Validate event type
    if (selectedEventType.value == null || selectedEventType.value!.isEmpty) {
      eventTypeError.value = 'Please select an event type';
      isValid = false;
    }

    // Validate venue
    if (selectedVenue.value == null || selectedVenue.value!.isEmpty) {
      venueError.value = 'Please select a venue';
      isValid = false;
    } else {
      venueError.value = '';
    }

    // Validate service type
    if (selectedServiceType.value == null) {
      serviceTypeError.value = 'Please select a service type';
      isValid = false;
    } else {
      serviceTypeError.value = '';
    }

    // Validate date
    if (selectedDate.value == null) {
      dateError.value = 'Event date is required';
      isValid = false;
    }

    // Validate start time
    if (selectedStartTime.value == null) {
      startTimeError.value = 'Start time is required';
      isValid = false;
    }

    // Validate end time
    if (selectedEndTime.value == null) {
      endTimeError.value = 'End time is required';
      isValid = false;
    }

    // Validate RSVP deadline
    if (selectedRsvpDeadline.value == null) {
      rsvpDeadlineError.value = 'RSVP deadline is required';
      isValid = false;
    }

    // Cross-validation for times
    if (isValid &&
        selectedStartTime.value != null &&
        selectedEndTime.value != null) {
      final startMinutes =
          selectedStartTime.value!.hour * 60 + selectedStartTime.value!.minute;
      final endMinutes =
          selectedEndTime.value!.hour * 60 + selectedEndTime.value!.minute;

      if (endMinutes <= startMinutes) {
        endTimeError.value = 'End time must be after start time';
        isValid = false;
      }
    }

    // Cross-validation for RSVP deadline
    if (isValid &&
        selectedDate.value != null &&
        selectedRsvpDeadline.value != null) {
      final eventDateTime = DateTime(
        selectedDate.value!.year,
        selectedDate.value!.month,
        selectedDate.value!.day,
        selectedStartTime.value?.hour ?? 0,
        selectedStartTime.value?.minute ?? 0,
      );

      if (selectedRsvpDeadline.value!.isAfter(eventDateTime)) {
        rsvpDeadlineError.value = 'RSVP deadline must be before event start';
        isValid = false;
      }
    }

    return isValid;
  }

  /// Validate step 2 - Description, Dress Code, Special Notes, Capacity
  bool validateStep2() {
    bool isValid = true;

    // Clear only step 2 related errors
    capacityError.value = '';

    // Validate capacity
    if (capacityController.text.trim().isEmpty) {
      capacityError.value = 'Capacity is required';
      isValid = false;
    } else {
      final capacity = int.tryParse(capacityController.text.trim());
      if (capacity == null || capacity <= 0) {
        capacityError.value = 'Please enter a valid capacity number';
        isValid = false;
      }
    }

    return isValid;
  }

  /// Update selected event type
  void updateEventType(String? eventType) {
    selectedEventType.value = eventType;
    if (eventType != null) {
      eventTypeError.value = '';
    }
  }

  /// Update selected service type
  void updateServiceType(ServiceType? serviceType) {
    selectedServiceType.value = serviceType;
    if (serviceType != null) {
      serviceTypeError.value = '';
    }
  }

  /// Update selected venue
  void updateVenue(String? venue) {
    print('Updating venue to: $venue');
    selectedVenue.value = venue;
    if (venue != null) {
      venueError.value = '';
    }
  }

  /// Update selected date
  void updateDate(DateTime? date) {
    selectedDate.value = date;
    if (date != null) {
      dateError.value = '';
    }
  }

  /// Update selected start time
  void updateStartTime(DateTime? dateTime) {
    if (dateTime != null) {
      selectedStartTime.value = TimeOfDay.fromDateTime(dateTime);
      startTimeError.value = '';
    }
  }

  /// Update selected end time
  void updateEndTime(DateTime? dateTime) {
    if (dateTime != null) {
      selectedEndTime.value = TimeOfDay.fromDateTime(dateTime);
      endTimeError.value = '';
    }
  }

  /// Update RSVP deadline
  void updateRsvpDeadline(DateTime? deadline) {
    selectedRsvpDeadline.value = deadline;
    if (deadline != null) {
      rsvpDeadlineError.value = '';
    }
  }

  /// Pick cover image from gallery
  Future<void> pickCoverImage() async {
    try {
      final XFile? image = await _imageServices.pickImage(ImageSource.gallery);
      if (image != null) {
        selectedCoverImage.value = image;
        coverImageError.value = '';
      }
    } catch (e) {
      coverImageError.value = 'Failed to pick image: ${e.toString()}';
      showError('Failed to pick image');
    }
  }

  /// Remove selected cover image
  void removeCoverImage() {
    selectedCoverImage.value = null;
    coverImageError.value = '';
  }

  /// Create Event instance from form data
  Event createEventInstance() {
    if (!validateStep1() || !validateStep2()) {
      throw Exception('Form validation failed');
    }

    final organisationId = _authController.organisationId;
    if (organisationId == null) {
      throw Exception('Organisation ID not found');
    }

    return Event(
      venueId: selectedVenue.value!,
      organisationId: organisationId,
      serviceType: selectedServiceType.value!,
      name: nameController.text.trim(),
      address: addressController.text.trim().isNotEmpty
          ? addressController.text.trim()
          : '', // Will be required later
      capacity: int.parse(capacityController.text.trim()),
      date: selectedDate.value!,
      startTime: selectedStartTime.value!,
      endTime: selectedEndTime.value!,
      rsvpDeadline: selectedRsvpDeadline.value!,
      eventType: selectedEventType.value!,
      timezone: 'UTC', // TODO: Add timezone selection
      location: null, // Optional field
      status: EventStatus.draft,
      description: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
      dressCode: dressCodeController.text.trim().isNotEmpty
          ? dressCodeController.text.trim()
          : null,
      plannerEmail: plannerEmailController.text.trim().isNotEmpty
          ? plannerEmailController.text.trim()
          : null,
      specialNotes: specialNotesController.text.trim().isNotEmpty
          ? specialNotesController.text.trim()
          : null,
      hideHostInfo: hideHostInfo.value,
    );
  }

  /// Submit the event to Firebase
  /// Returns the saved Event (with eventId populated).
  Future<Event> submitEvent() async {
    try {
      isLoading.value = true;

      // Create event instance
      var event = createEventInstance();

      // Upload cover image if selected
      if (selectedCoverImage.value != null) {
        try {
          final imagePath =
              await _storageServices.uploadImage(selectedCoverImage.value!);
          // create a new event instance with coverImageUrl set
          event = event.copyWith(coverImageUrl: imagePath);
        } catch (e) {
          // If image upload fails, continue without image
          print('Failed to upload cover image: $e');
          showWarning('Event created but cover image upload failed');
        }
      }

      // Save to Firebase and get saved event (with eventId)
      final savedEvent = await _firestoreServices.saveEvent(event);
      print('Saved event: ${savedEvent.toString()}');

      // Success feedback (global snackbar)
      snackbar.showSuccessMessage('Event created successfully!');

      // Signal UI to navigate back
      eventListController.addCreatedEventToList(savedEvent);
      await _storageServices.loadImage(savedEvent);
      shouldPop.value = true;

      return savedEvent;
    } catch (e) {
      // Error feedback
      showError('Failed to create event: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset form to initial state
  void resetForm() {
    // Clear controllers
    nameController.clear();
    capacityController.clear();
    descriptionController.clear();
    addressController.clear();
    dressCodeController.clear();
    plannerEmailController.clear();
    specialNotesController.clear();

    // Reset selections
    selectedEventType.value = null;
    selectedDate.value = null;
    selectedStartTime.value = null;
    selectedEndTime.value = null;
    selectedRsvpDeadline.value = null;
    hideHostInfo.value = false;
    selectedCoverImage.value = null;
    coverImageError.value = '';
    snackBarMessage.value = null;
    shouldPop.value = false;

    // Clear errors
    clearErrors();
  }

  /// Clear snackbar message
  void clearSnackBarMessage() {
    snackBarMessage.value = null;
  }

  /// Clear navigation flag after handling
  void clearShouldPop() {
    shouldPop.value = false;
  }

  /// Show success message
  void showSuccess(String message) {
    snackBarMessage.value = SnackBarMessage(
      message: message,
      type: SnackBarType.success,
    );
  }

  /// Show error message
  void showError(String message) {
    snackBarMessage.value = SnackBarMessage(
      message: message,
      type: SnackBarType.error,
    );
  }

  /// Show warning message
  void showWarning(String message) {
    snackBarMessage.value = SnackBarMessage(
      message: message,
      type: SnackBarType.warning,
    );
  }
}
