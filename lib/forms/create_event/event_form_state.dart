import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class EventFormState {
  /// Creates a new empty EventFormState instance
  EventFormState();

  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dressCodeController = TextEditingController();
  final TextEditingController plannerEmailController = TextEditingController();
  final TextEditingController specialNotesController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();

  // Core selections / primitives
  ServiceType? serviceType;
  DateTime? date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? rsvpDeadline;
  String? selectedEventType;
  String? selectedTimezone;
  bool hideHostInfo = false;
  int? maxInviteByGuest; // Maximum number of guests each invitee can bring (0-5)

  // Location & images
  LatLng? selectedLocation;
  XFile? coverImage;
  List<XFile> additionalImages = [];

  // NEW: fields used by controllers & Event factory
  /// The venue object that was selected in the form (must have .id)
  /// Type is dynamic to avoid circular import — change to your Venue type if you prefer.
  dynamic selectedVenue;

  /// optional preselected menu id / list from the form
  String? selectedMenuId;
  List<String>? selectedMenuItemIds;

  /// optional demographic question set id chosen in the form
  String? selectedDemographicQuestionSetId;

  /// optional list of categories the user may choose from
  List<MenuCategory>? selectableMenuCategories;

  /// optional list of selected menus (legacy field)
  List<String>? selectedMenus;

  /// Convenience: create EventFormState populated from existing Event
  factory EventFormState.fromEvent(Event event) {
    final state = EventFormState();

    // Initialize text controllers
    state.nameController.text = event.name;
    state.addressController.text = event.address;
    state.capacityController.text = event.capacity.toString();
    state.descriptionController.text = event.description ?? '';
    state.dressCodeController.text = event.dressCode ?? '';
    state.plannerEmailController.text = event.plannerEmail ?? '';
    state.specialNotesController.text = event.specialNotes ?? '';

    // Initialize date/time fields
    state.date = event.date;
    state.startTime = event.startTime;
    state.endTime = event.endTime;
    state.rsvpDeadline = event.rsvpDeadline;

    // Initialize selection fields
    state.selectedEventType = event.eventType;
    state.selectedTimezone = event.timezone;
    state.selectedLocation = event.location;

    // Initialize other fields
    state.serviceType = event.serviceType;
    state.hideHostInfo = event.hideHostInfo;
    state.maxInviteByGuest = event.maxInviteByGuest;
    state.coverImage = event.coverImage;

    // NEW fields
    state.selectedVenue = {
      'id': event.venueId
    }; // lightweight placeholder — replace with actual Venue if available
    state.selectedMenuId = event.selectedMenuId;
    state.selectedMenuItemIds = event.selectedMenuItemIds;
    state.selectedDemographicQuestionSetId =
        event.selectedDemographicQuestionSetId;
    state.selectableMenuCategories = event.selectableCategories;
    state.selectedMenus = event.selectedMenus;

    return state;
  }

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    dressCodeController.dispose();
    plannerEmailController.dispose();
    specialNotesController.dispose();
    capacityController.dispose();
  }

  @override
  String toString() {
    return '''
EventFormState {
  serviceType: $serviceType
  name: ${nameController.text}
  address: ${addressController.text}
  description: ${descriptionController.text}
  dressCode: ${dressCodeController.text}
  plannerEmail: ${plannerEmailController.text}
  specialNotes: ${specialNotesController.text}
  capacity: ${capacityController.text}
  date: $date
  startTime: $startTime
  endTime: $endTime
  rsvpDeadline: $rsvpDeadline
  eventType: $selectedEventType
  timezone: $selectedTimezone
  hideHostInfo: $hideHostInfo
  maxInviteByGuest: $maxInviteByGuest
  location: $selectedLocation
  selectedVenue: ${selectedVenue != null ? (selectedVenue is Map ? selectedVenue['id'] : selectedVenue?.id) : null}
  selectedMenuId: $selectedMenuId
  selectedMenuItemIds: $selectedMenuItemIds
  selectedDemographicQuestionSetId: $selectedDemographicQuestionSetId
  selectableMenuCategories: $selectableMenuCategories
  selectedMenus: $selectedMenus
  hasCoverImage: ${coverImage != null}
  additionalImages: ${additionalImages.length}
}''';
  }
}
