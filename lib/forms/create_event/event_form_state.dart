import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';

class EventFormState {
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
