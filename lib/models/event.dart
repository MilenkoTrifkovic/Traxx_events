import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:traxx_wepapp/forms/create_event/event_validator.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

class Event {
  final String name;
  final String address;
  final int capacity;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime rsvpDeadline;
  final String eventType;
  final String timezone;
  final LatLng location;
  final XFile? coverImage;
  String? coverImageUrl;

  // Optional fields
  final String? description;
  final String? dressCode;
  final String? plannerEmail;
  final String? specialNotes;
  final bool hideHostInfo;

  Event({
    required this.name,
    required this.address,
    required this.capacity,
    required this.startDateTime,
    required this.endDateTime,
    required this.rsvpDeadline,
    required this.eventType,
    required this.timezone,
    required this.location,
    this.coverImage,
    this.coverImageUrl,
    this.description,
    this.dressCode,
    this.plannerEmail,
    this.specialNotes,
    this.hideHostInfo = false,
  });

  /// Creates an Event instance from the form state
  ///
  /// Parameters:
  ///   state: EventFormState containing all form field values
  ///
  /// Returns:
  ///   A new Event instance populated with form data
  ///
  /// Throws:
  ///   ValidationError if required fields are missing or invalid
  factory Event.fromFormState(EventFormState state) {
    // Validate all required fields
    EventValidator.validateRequiredFields(
      name: state.nameController.text,
      address: state.addressController.text,
      capacity: state.capacityController.text,
      startDateTime: state.startDateTime,
      endDateTime: state.endDateTime,
      rsvpDeadline: state.rsvpDeadline,
      eventType: state.selectedEventType,
      timezone: state.selectedTimezone,
      location: state.selectedLocation,
      coverImage: state.coverImage,
    );
    final capacity = int.parse(state.capacityController.text);

    return Event(
      name: state.nameController.text,
      address: state.addressController.text,
      capacity: capacity,
      startDateTime: state.startDateTime!,
      endDateTime: state.endDateTime!,
      rsvpDeadline: state.rsvpDeadline!,
      eventType: state.selectedEventType!,
      timezone: state.selectedTimezone!,
      location: state.selectedLocation!,
      coverImage: state.coverImage!,
      description: state.descriptionController.text.isNotEmpty
          ? state.descriptionController.text
          : null,
      dressCode: state.dressCodeController.text.isNotEmpty
          ? state.dressCodeController.text
          : null,
      plannerEmail: state.plannerEmailController.text.isNotEmpty
          ? state.plannerEmailController.text
          : null,
      specialNotes: state.specialNotesController.text.isNotEmpty
          ? state.specialNotesController.text
          : null,
      hideHostInfo: state.hideHostInfo,
    );
  }

  /// Converts the Event instance to a JSON map for Firestore storage
  ///
  /// Returns:
  ///   Map<String, dynamic> containing event data formatted for Firestore
  ///   with all DateTime fields converted to UTC Timestamps
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'capacity': capacity,
      'startDateTime': Timestamp.fromDate(startDateTime.toUtc()),
      'endDateTime': Timestamp.fromDate(endDateTime.toUtc()),
      'rsvpDeadline': Timestamp.fromDate(rsvpDeadline.toUtc()),
      'eventType': eventType,
      'timezone': timezone,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'description': description,
      'dressCode': dressCode,
      'plannerEmail': plannerEmail,
      'specialNotes': specialNotes,
      'hideHostInfo': hideHostInfo,
      'coverImageUrl': coverImageUrl,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  @override
  String toString() {
    return '''
Event {
  name: $name
  address: $address
  capacity: $capacity
  startDateTime: $startDateTime
  endDateTime: $endDateTime
  rsvpDeadline: $rsvpDeadline
  eventType: $eventType
  timezone: $timezone
  location: $location
  coverImage: ${coverImage?.path}
  description: $description
  dressCode: $dressCode
  plannerEmail: $plannerEmail
  specialNotes: $specialNotes
  hideHostInfo: $hideHostInfo
}''';
  }
}
