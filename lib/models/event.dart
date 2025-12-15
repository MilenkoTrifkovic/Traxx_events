import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:traxx_wepapp/forms/create_event/event_validator.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

// class Event {
//   final bool? isDisabled;
//   final String? eventId;
//   final String organisationId;
//   final String venueId;
//   final ServiceType serviceType;
//   final String name;
//   final String address;
//   final int capacity;
//   final DateTime date;
//   final TimeOfDay startTime;
//   final TimeOfDay endTime;
//   final DateTime rsvpDeadline;
//   final String eventType;
//   final String timezone;
//   final LatLng? location;
//   final EventStatus status;
//   List<MenuCategory> selectableCategories;
//   List<String>? selectedMenus;

//   // Optional fields
//   final XFile? coverImage;
//   String? coverImageUrl;
//   String? coverImageDownloadUrl;
//   final String? description;
//   final String? dressCode;
//   final String? plannerEmail;
//   final String? specialNotes;
//   final bool hideHostInfo;

//   Event({
//     this.isDisabled,
//     this.eventId,
//     required this.organisationId,
//     required this.venueId,
//     required this.serviceType,
//     required this.name,
//     required this.address,
//     required this.capacity,
//     required this.date,
//     required this.startTime,
//     required this.endTime,
//     required this.rsvpDeadline,
//     required this.eventType,
//     required this.timezone,
//     this.location,
//     this.status = EventStatus.draft,
//     this.coverImage,
//     this.coverImageUrl,
//     this.coverImageDownloadUrl,
//     this.description,
//     this.dressCode,
//     this.plannerEmail,
//     this.specialNotes,
//     this.hideHostInfo = false,
//     this.selectableCategories = const [],
//     this.selectedMenus,
//   });

//   /// Creates an Event instance from a Firestore document
//   ///
//   /// Parameters:
//   ///   doc: DocumentSnapshot containing event data from Firestore
//   ///
//   /// Returns:
//   ///   A new Event instance populated with Firestore data
//   factory Event.fromFirestore(dynamic doc) {
//     // factory Event.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data();

//     // Extract location data (optional)
//     final locMap = data['location'] as Map<String, dynamic>?;
//     final location = locMap != null
//         ? LatLng(
//             locMap['latitude'] as double,
//             locMap['longitude'] as double,
//           )
//         : null;

//     // Convert Firestore timestamps to DateTime and extract date/time components
//     final startDateTime = (data['startDateTime'] as Timestamp).toDate();
//     final endDateTime = (data['endDateTime'] as Timestamp).toDate();
//     final rsvpDeadline = (data['rsvpDeadline'] as Timestamp).toDate();

//     return Event(
//       eventId: data['eventId'] as String?,
//       organisationId: data['organisationId'] as String,
//       venueId: data['venueId'] as String,
//       name: data['name'] as String,
//       address: data['address'] as String,
//       capacity: data['capacity'] as int,
//       date:
//           DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
//       startTime: TimeOfDay.fromDateTime(startDateTime),
//       endTime: TimeOfDay.fromDateTime(endDateTime),
//       rsvpDeadline: rsvpDeadline,
//       eventType: data['eventType'] as String,
//       timezone: data['timezone'] as String,
//       location: location,
//       status:
//           EventStatusExtension.fromString(data['status'] as String? ?? 'draft'),
//       coverImageUrl: data['coverImageUrl'] as String?,
//       description: data['description'] as String?,
//       dressCode: data['dressCode'] as String?,
//       plannerEmail: data['plannerEmail'] as String?,
//       specialNotes: data['specialNotes'] as String?,
//       hideHostInfo: data['hideHostInfo'] as bool? ?? false,
//       isDisabled: data['isDisabled'] as bool?,
//       serviceType: ServiceType.values.firstWhere(
//         (e) => e.name == (data['serviceType']),
//         orElse: () => ServiceType.buffet,
//       ),
//       selectableCategories: (data['selectableMenuCategories'] as List<dynamic>?)
//               ?.map((name) =>
//                   MenuCategory.values.firstWhere((e) => e.name == name))
//               .toList() ??
//           [],
//       selectedMenus: (data['selectedMenus'] as List<dynamic>?)
//               ?.map((e) => e as String)
//               .toList() ??
//           [],
//     );
//   }

//   /// Creates an Event instance from the form state
//   ///
//   /// Parameters:
//   ///   state: EventFormState containing all form field values
//   ///   organisationId: The organisation ID to associate with the event
//   ///
//   /// Returns:
//   ///   A new Event instance populated with form data
//   ///
//   /// Throws:
//   ///   ValidationError if required fields are missing or invalid

//   factory Event.fromFormState(EventFormState state, String organisationId) {
//     // Validate all required fields
//     EventValidator.validateRequiredFields(
//       name: state.nameController.text,
//       address: state.addressController.text,
//       capacity: state.capacityController.text,
//       serviceType: state.serviceType,
//       date: state.date,
//       startTime: state.startTime,
//       endTime: state.endTime,
//       rsvpDeadline: state.rsvpDeadline,
//       eventType: state.selectedEventType,
//       timezone: state.selectedTimezone,
//       location: state.selectedLocation,
//     );
//     final capacity = int.parse(state.capacityController.text);

//     return Event(
//       venueId: 'state.selectedVenue!.id!',
//       organisationId: organisationId,
//       serviceType: state.serviceType!,
//       name: state.nameController.text,
//       address: state.addressController.text,
//       capacity: capacity,
//       date: state.date!,
//       startTime: state.startTime!,
//       endTime: state.endTime!,
//       rsvpDeadline: state.rsvpDeadline!,
//       eventType: state.selectedEventType!,
//       timezone: state.selectedTimezone!,
//       location: state.selectedLocation,
//       status: EventStatus.draft,
//       coverImage: state.coverImage,
//       description: state.descriptionController.text.isNotEmpty
//           ? state.descriptionController.text
//           : null,
//       dressCode: state.dressCodeController.text.isNotEmpty
//           ? state.dressCodeController.text
//           : null,
//       plannerEmail: state.plannerEmailController.text.isNotEmpty
//           ? state.plannerEmailController.text
//           : null,
//       specialNotes: state.specialNotesController.text.isNotEmpty
//           ? state.specialNotesController.text
//           : null,
//       hideHostInfo: state.hideHostInfo,
//     );
//   }

//   /// Converts the Event instance to a JSON map for Firestore storage
//   ///
//   /// Returns:
//   ///   Map<String, dynamic> containing event data formatted for Firestore
//   ///   with all DateTime fields converted to UTC Timestamps
//   Map<String, dynamic> toJson() {
//     // Combine date with start and end times to create full DateTime objects
//     final startDateTime = DateTime(
//       date.year,
//       date.month,
//       date.day,
//       startTime.hour,
//       startTime.minute,
//     );
//     final endDateTime = DateTime(
//       date.year,
//       date.month,
//       date.day,
//       endTime.hour,
//       endTime.minute,
//     );

//     return {
//       'eventId': eventId ?? '',
//       'organisationId': organisationId,
//       'venueId': venueId,
//       'name': name,
//       'address': address,
//       'capacity': capacity,
//       'startDateTime': Timestamp.fromDate(startDateTime.toUtc()),
//       'endDateTime': Timestamp.fromDate(endDateTime.toUtc()),
//       'rsvpDeadline': Timestamp.fromDate(rsvpDeadline.toUtc()),
//       'eventType': eventType,
//       'timezone': timezone,
//       'location': location != null
//           ? {
//               'latitude': location!.latitude,
//               'longitude': location!.longitude,
//             }
//           : null,
//       'description': description,
//       'dressCode': dressCode,
//       'plannerEmail': plannerEmail,
//       'specialNotes': specialNotes,
//       'hideHostInfo': hideHostInfo,
//       'coverImageUrl': coverImageUrl,
//       'serviceType': serviceType.name,
//       'status': status.statusName,
//       'createdAt': Timestamp.now(),
//       'updatedAt': Timestamp.now(),
//       'selectableCategories': selectableCategories.map((e) => e.name).toList(),
//       'selectedMenus': selectedMenus ?? [],
//       'isDisabled': isDisabled ?? false,
//     };
//   }

//   /// Creates a copy of this Event with the specified fields replaced with new values.
//   Event copyWith({
//     String? eventId,
//     String? id,
//     String? organisationId,
//     String? venueId,
//     ServiceType? serviceType,
//     String? name,
//     String? address,
//     int? capacity,
//     DateTime? date,
//     TimeOfDay? startTime,
//     TimeOfDay? endTime,
//     DateTime? rsvpDeadline,
//     String? eventType,
//     String? timezone,
//     LatLng? location,
//     EventStatus? status,
//     XFile? coverImage,
//     String? coverImageUrl,
//     String? coverImageDownloadUrl,
//     String? description,
//     String? dressCode,
//     String? plannerEmail,
//     String? specialNotes,
//     bool? hideHostInfo,
//     List<MenuCategory>? selectableCategories,
//     bool? isDisabled,
//   }) {
//     return Event(
//       eventId: eventId ?? this.eventId,
//       organisationId: organisationId ?? this.organisationId,
//       venueId: venueId ?? this.venueId,
//       serviceType: serviceType ?? this.serviceType,
//       name: name ?? this.name,
//       address: address ?? this.address,
//       capacity: capacity ?? this.capacity,
//       date: date ?? this.date,
//       startTime: startTime ?? this.startTime,
//       endTime: endTime ?? this.endTime,
//       rsvpDeadline: rsvpDeadline ?? this.rsvpDeadline,
//       eventType: eventType ?? this.eventType,
//       timezone: timezone ?? this.timezone,
//       location: location ?? this.location,
//       status: status ?? this.status,
//       coverImage: coverImage ?? this.coverImage,
//       coverImageUrl: coverImageUrl ?? this.coverImageUrl,
//       coverImageDownloadUrl:
//           coverImageDownloadUrl ?? this.coverImageDownloadUrl,
//       description: description ?? this.description,
//       dressCode: dressCode ?? this.dressCode,
//       plannerEmail: plannerEmail ?? this.plannerEmail,
//       specialNotes: specialNotes ?? this.specialNotes,
//       hideHostInfo: hideHostInfo ?? this.hideHostInfo,
//       selectableCategories: selectableCategories ?? this.selectableCategories,
//       isDisabled: isDisabled ?? this.isDisabled,
//     );
//   }

//   @override
//   String toString() {
//     return '''
// Event {
//   eventId: $eventId
//   organisationId: $organisationId
//   serviceType: $serviceType
//   name: $name
//   address: $address
//   capacity: $capacity
//   date: $date
//   startTime: $startTime
//   endTime: $endTime
//   rsvpDeadline: $rsvpDeadline
//   eventType: $eventType
//   timezone: $timezone
//   location: $location
//   status: $status
//   coverImage: ${coverImage?.path}
//   description: $description
//   dressCode: $dressCode
//   plannerEmail: $plannerEmail
//   specialNotes: $specialNotes
//   hideHostInfo: $hideHostInfo
//   downloadURL: $coverImageDownloadUrl
//   selectableCategories: $selectableCategories
//   isDisabled: $isDisabled
// }''';
//   }
// }

class Event {
  final bool? isDisabled;
  final String? eventId;
  final String organisationId;
  final String venueId;
  final ServiceType serviceType;
  final String name;
  final String address;
  final int capacity;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime rsvpDeadline;
  final String eventType;
  final String timezone;
  final LatLng? location;
  final EventStatus status;
  List<MenuCategory> selectableCategories;
  List<String>? selectedMenus;

  // NEW fields required by controllers
  final String? selectedMenuId;
  final List<String>? selectedMenuItemIds;
  final String? selectedDemographicQuestionSetId;

  // Optional fields
  final XFile? coverImage;
  String? coverImageUrl;
  String? coverImageDownloadUrl;
  final String? description;
  final String? dressCode;
  final String? plannerEmail;
  final String? specialNotes;
  final bool hideHostInfo;

  Event({
    this.isDisabled,
    this.eventId,
    required this.organisationId,
    required this.venueId,
    required this.serviceType,
    required this.name,
    required this.address,
    required this.capacity,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rsvpDeadline,
    required this.eventType,
    required this.timezone,
    this.location,
    this.status = EventStatus.draft,
    this.coverImage,
    this.coverImageUrl,
    this.coverImageDownloadUrl,
    this.description,
    this.dressCode,
    this.plannerEmail,
    this.specialNotes,
    this.hideHostInfo = false,
    this.selectableCategories = const [],
    this.selectedMenus,
    // new fields
    this.selectedMenuId,
    this.selectedMenuItemIds,
    this.selectedDemographicQuestionSetId,
  });

  /// Creates an Event instance from a Firestore document
  factory Event.fromFirestore(dynamic doc) {
    final data = doc.data();

    // Safely parse location map (if present)
    final locMap = data['location'] as Map<String, dynamic>?;
    final location = locMap != null &&
            locMap['latitude'] != null &&
            locMap['longitude'] != null
        ? LatLng(
            (locMap['latitude'] as num).toDouble(),
            (locMap['longitude'] as num).toDouble(),
          )
        : null;

    // Parse timestamps (defensive: check existence)
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return (value).toDate();
      if (value is DateTime) return value;
      throw ArgumentError('Unsupported timestamp value: $value');
    }

    final startDateTime = data['startDateTime'] != null
        ? parseTimestamp(data['startDateTime'])
        : DateTime.now();
    final endDateTime = data['endDateTime'] != null
        ? parseTimestamp(data['endDateTime'])
        : DateTime.now();
    final rsvpDeadline = data['rsvpDeadline'] != null
        ? parseTimestamp(data['rsvpDeadline'])
        : DateTime.now();

    // read lists safely
    final selectedMenusList = (data['selectedMenus'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    final selectedMenuItemIdsList =
        (data['selectedMenuItemIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList();

    return Event(
      eventId: data['eventId'] as String?,
      organisationId: data['organisationId'] as String,
      venueId: data['venueId'] as String,
      name: data['name'] as String,
      address: data['address'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      date:
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      startTime: TimeOfDay.fromDateTime(startDateTime),
      endTime: TimeOfDay.fromDateTime(endDateTime),
      rsvpDeadline: rsvpDeadline,
      eventType: data['eventType'] as String? ?? '',
      timezone: data['timezone'] as String? ?? 'UTC',
      location: location,
      status:
          EventStatusExtension.fromString(data['status'] as String? ?? 'draft'),
      coverImageUrl: data['coverImageUrl'] as String?,
      description: data['description'] as String?,
      dressCode: data['dressCode'] as String?,
      plannerEmail: data['plannerEmail'] as String?,
      specialNotes: data['specialNotes'] as String?,
      hideHostInfo: data['hideHostInfo'] as bool? ?? false,
      isDisabled: data['isDisabled'] as bool?,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == (data['serviceType']),
        orElse: () => ServiceType.buffet,
      ),
      selectableCategories: (data['selectableMenuCategories'] as List<dynamic>?)
              ?.map((name) =>
                  MenuCategory.values.firstWhere((e) => e.name == name))
              .toList() ??
          [],
      selectedMenus: selectedMenusList,
      // NEW fields
      selectedMenuId: data['selectedMenuId'] as String?,
      selectedMenuItemIds: selectedMenuItemIdsList,
      selectedDemographicQuestionSetId:
          data['selectedDemographicQuestionSetId'] as String?,
    );
  }

  /// Creates an Event instance from the form state
  ///
  /// Assumptions about EventFormState:
  ///  - nameController: TextEditingController
  ///  - addressController: TextEditingController
  ///  - capacityController: TextEditingController (numeric)
  ///  - serviceType: String or ServiceType (form stores string like 'buffet'/'plated')
  ///  - date: DateTime?
  ///  - startTime: TimeOfDay?
  ///  - endTime: TimeOfDay?
  ///  - rsvpDeadline: DateTime?
  ///  - selectedEventType: String?
  ///  - selectedTimezone: String?
  ///  - selectedLocation: LatLng? (optional)
  ///  - selectedVenue: Venue-like object with id (required)
  ///  - coverImage: XFile?
  ///  - descriptionController, dressCodeController, plannerEmailController, specialNotesController: TextEditingController
  ///  - hideHostInfo: bool
  ///  - selectableMenuCategories: List<MenuCategory>?
  ///  - selectedMenus: List<String>?
  factory Event.fromFormState(EventFormState state, String organisationId) {
    // Basic validation — throw useful errors early if critical data missing
    if (state.selectedVenue == null) {
      throw ArgumentError('selectedVenue must be provided in the form state');
    }
    if (state.date == null) {
      throw ArgumentError('date must be provided in the form state');
    }
    if (state.startTime == null || state.endTime == null) {
      throw ArgumentError(
          'startTime and endTime must be provided in the form state');
    }

    // Parse capacity safely
    int parsedCapacity = 0;
    try {
      parsedCapacity = state.capacityController.text.trim().isNotEmpty == true
          ? int.parse(state.capacityController.text.trim())
          : 0;
    } catch (_) {
      parsedCapacity = 0;
    }

    // ServiceType: accept either a string (enum name) or ServiceType value from the form
    ServiceType parsedServiceType;
    if (state.serviceType is ServiceType) {
      parsedServiceType = state.serviceType as ServiceType;
    } else if (state.serviceType is String) {
      parsedServiceType = ServiceType.values.firstWhere(
          (e) => e.name == (state.serviceType as String),
          orElse: () => ServiceType.buffet);
    } else {
      parsedServiceType = ServiceType.buffet;
    }

    // Compose DateTimes for start/end using date + startTime/endTime from form
    final date = state.date!;
    final dynamic selVenue = state.selectedVenue;
    final String venueId;
    if (selVenue == null) {
      throw ArgumentError('selectedVenue must be provided in the form state');
    } else if (selVenue is String) {
      venueId = selVenue;
    } else if (selVenue is Map) {
      venueId = selVenue['id'] as String;
    } else {
      // assume object with .id
      venueId = (selVenue.id as String);
    }
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      state.startTime!.hour,
      state.startTime!.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      state.endTime!.hour,
      state.endTime!.minute,
    );

    return Event(
      organisationId: organisationId,
      venueId: venueId,
      serviceType: parsedServiceType,
      name: state.nameController.text.trim() ?? '',
      address: state.addressController.text.trim() ?? '',
      capacity: parsedCapacity,
      date: DateTime(date.year, date.month, date.day),
      startTime: state.startTime!,
      endTime: state.endTime!,
      rsvpDeadline: state.rsvpDeadline ?? DateTime.now(),
      eventType: state.selectedEventType ?? '',
      timezone: state.selectedTimezone ?? 'UTC',
      location: state.selectedLocation,
      status: EventStatus.draft,
      coverImage: state.coverImage,
      description: state.descriptionController.text.trim().isNotEmpty == true
          ? state.descriptionController.text.trim()
          : null,
      dressCode: state.dressCodeController.text.trim().isNotEmpty == true
          ? state.dressCodeController.text.trim()
          : null,
      plannerEmail: state.plannerEmailController.text.trim().isNotEmpty == true
          ? state.plannerEmailController.text.trim()
          : null,
      specialNotes: state.specialNotesController.text.trim().isNotEmpty == true
          ? state.specialNotesController.text.trim()
          : null,
      hideHostInfo: state.hideHostInfo ?? false,
      selectableCategories:
          state.selectableMenuCategories ?? const <MenuCategory>[],
      selectedMenus: state.selectedMenus,
      // new fields (optional initial values from form)
      selectedMenuId: state.selectedMenuId,
      selectedMenuItemIds: state.selectedMenuItemIds,
      selectedDemographicQuestionSetId: state.selectedDemographicQuestionSetId,
    );
  }

  /// Converts the Event instance to a JSON map for Firestore storage
  Map<String, dynamic> toJson() {
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    return {
      'eventId': eventId ?? '',
      'organisationId': organisationId,
      'venueId': venueId,
      'name': name,
      'address': address,
      'capacity': capacity,
      'startDateTime': Timestamp.fromDate(startDateTime.toUtc()),
      'endDateTime': Timestamp.fromDate(endDateTime.toUtc()),
      'rsvpDeadline': Timestamp.fromDate(rsvpDeadline.toUtc()),
      'eventType': eventType,
      'timezone': timezone,
      'location': location != null
          ? {
              'latitude': location!.latitude,
              'longitude': location!.longitude,
            }
          : null,
      'description': description,
      'dressCode': dressCode,
      'plannerEmail': plannerEmail,
      'specialNotes': specialNotes,
      'hideHostInfo': hideHostInfo,
      'coverImageUrl': coverImageUrl,
      'serviceType': serviceType.name,
      'status': status.statusName,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'selectableMenuCategories':
          selectableCategories.map((e) => e.name).toList(),
      'selectedMenus': selectedMenus ?? [],
      // NEW fields included
      'selectedMenuId': selectedMenuId,
      'selectedMenuItemIds': selectedMenuItemIds ?? [],
      'selectedDemographicQuestionSetId': selectedDemographicQuestionSetId,
      'isDisabled': isDisabled ?? false,
    };
  }

  /// Creates a copy of this Event with the specified fields replaced
  Event copyWith({
    String? eventId,
    String? id,
    String? organisationId,
    String? venueId,
    ServiceType? serviceType,
    String? name,
    String? address,
    int? capacity,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? rsvpDeadline,
    String? eventType,
    String? timezone,
    LatLng? location,
    EventStatus? status,
    XFile? coverImage,
    String? coverImageUrl,
    String? coverImageDownloadUrl,
    String? description,
    String? dressCode,
    String? plannerEmail,
    String? specialNotes,
    bool? hideHostInfo,
    List<MenuCategory>? selectableCategories,
    bool? isDisabled,
    // NEW copyWith options:
    List<String>? selectedMenus,
    String? selectedMenuId,
    List<String>? selectedMenuItemIds,
    String? selectedDemographicQuestionSetId,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      organisationId: organisationId ?? this.organisationId,
      venueId: venueId ?? this.venueId,
      serviceType: serviceType ?? this.serviceType,
      name: name ?? this.name,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rsvpDeadline: rsvpDeadline ?? this.rsvpDeadline,
      eventType: eventType ?? this.eventType,
      timezone: timezone ?? this.timezone,
      location: location ?? this.location,
      status: status ?? this.status,
      coverImage: coverImage ?? this.coverImage,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageDownloadUrl:
          coverImageDownloadUrl ?? this.coverImageDownloadUrl,
      description: description ?? this.description,
      dressCode: dressCode ?? this.dressCode,
      plannerEmail: plannerEmail ?? this.plannerEmail,
      specialNotes: specialNotes ?? this.specialNotes,
      hideHostInfo: hideHostInfo ?? this.hideHostInfo,
      selectableCategories: selectableCategories ?? this.selectableCategories,
      isDisabled: isDisabled ?? this.isDisabled,
      selectedMenus: selectedMenus ?? this.selectedMenus,
      selectedMenuId: selectedMenuId ?? this.selectedMenuId,
      selectedMenuItemIds: selectedMenuItemIds ?? this.selectedMenuItemIds,
      selectedDemographicQuestionSetId: selectedDemographicQuestionSetId ??
          this.selectedDemographicQuestionSetId,
    );
  }

  @override
  String toString() {
    return '''
Event {
  eventId: $eventId
  organisationId: $organisationId
  serviceType: $serviceType
  name: $name
  address: $address
  capacity: $capacity
  date: $date
  startTime: $startTime
  endTime: $endTime
  rsvpDeadline: $rsvpDeadline
  eventType: $eventType
  timezone: $timezone
  location: $location
  status: $status
  coverImage: ${coverImage?.path}
  description: $description
  dressCode: $dressCode
  plannerEmail: $plannerEmail
  specialNotes: $specialNotes
  hideHostInfo: $hideHostInfo
  downloadURL: $coverImageDownloadUrl
  selectableCategories: $selectableCategories
  selectedMenus: $selectedMenus
  selectedMenuId: $selectedMenuId
  selectedMenuItemIds: $selectedMenuItemIds
  selectedDemographicQuestionSetId: $selectedDemographicQuestionSetId
  isDisabled: $isDisabled
}''';
  }
}
