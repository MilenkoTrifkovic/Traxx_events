import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/static_data.dart';

class EventFormState {
  /// Creates a new empty EventFormState instance
  EventFormState();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dressCodeController = TextEditingController();
  final TextEditingController plannerEmailController = TextEditingController();
  final TextEditingController specialNotesController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();

  DateTime? startDateTime;
  DateTime? endDateTime;
  DateTime? rsvpDeadline;
  String? selectedEventType;
  String? selectedTimezone;
  bool hideHostInfo = false;
  LatLng? selectedLocation;
  XFile? coverImage;
  List<XFile> additionalImages = [];

  /// Creates an EventFormState instance from an existing Event
  ///
  /// This factory constructor initializes all form controllers and fields
  /// with values from an existing Event object.
  ///
  /// Parameters:
  ///   event: The Event object to initialize the form state from
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
    state.startDateTime = event.startDateTime;
    state.endDateTime = event.endDateTime;
    state.rsvpDeadline = event.rsvpDeadline;

    // Initialize selection fields
    state.selectedEventType = StaticData.eventTypes.firstWhere(
      (type) => type == event.eventType,
    );
    state.selectedTimezone = event.timezone;
    state.selectedLocation = event.location;

    // Initialize other fields
    state.hideHostInfo = event.hideHostInfo;
    state.coverImage = event.coverImage;

    print('Factory EventFormState created from Event: ${event.toString()}');
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

  Map<String, dynamic> getFormData() {
    return {
      'name': nameController.text,
      'address': addressController.text,
      'description': descriptionController.text,
      'dressCode': dressCodeController.text,
      'plannerEmail': plannerEmailController.text,
      'specialNotes': specialNotesController.text,
      'capacity': int.tryParse(capacityController.text),
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'rsvpDeadline': rsvpDeadline,
      'selectedEventType': selectedEventType,
      'selectedTimezone': selectedTimezone,
      'hideHostInfo': hideHostInfo,
    };
  }

  @override
  String toString() {
    return '''
EventFormState {
  name: ${nameController.text}
  address: ${addressController.text}
  description: ${descriptionController.text}
  dressCode: ${dressCodeController.text}
  plannerEmail: ${plannerEmailController.text}
  specialNotes: ${specialNotesController.text}
  capacity: ${capacityController.text}
  startDateTime: $startDateTime
  endDateTime: $endDateTime
  rsvpDeadline: $rsvpDeadline
  eventType: $selectedEventType
  timezone: $selectedTimezone
  hideHostInfo: $hideHostInfo
  location: $selectedLocation
  hasCoverImage: ${coverImage != null}
  additionalImages: ${additionalImages.length}
}''';
  }
}
