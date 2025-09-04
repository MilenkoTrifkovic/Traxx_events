import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/utils/constants.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

/// A widget that provides an interactive map interface for selecting event locations.
///
/// This widget integrates with Google Maps to allow users to:
/// - Search for locations using the Google Places API
/// - Pick locations directly from the map
/// - View  the formatted address
///
/// The selected location data is stored in the [EventFormState] and validated
/// through the provided form field keys.
class LocationPickerScreen extends StatefulWidget {
  /// Form field keys for validation and state management.
  /// Expected keys include 'location' for the address field.
  final Map<String, GlobalKey<FormFieldState>> fieldKeys;

  const LocationPickerScreen({super.key, required this.fieldKeys});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

/// The state management class for the LocationPickerScreen widget.
/// Handles the map interaction, address formatting, and form state updates.
class _LocationPickerScreenState extends State<LocationPickerScreen> {
  /// Reference to the global event form state
  late final EventFormState formState;

  /// Controller for the formatted address text field
  /// This displays and allows editing of the selected location's address
  late final TextEditingController formattedAdressController =
      TextEditingController();

  @override
  void initState() {
    /// Initialize the form state by finding the global EventFormState instance
    formState = Get.find<EventFormState>();
    HostController hostController = Get.find<HostController>();
    formattedAdressController.text =
        hostController.isEditingEvent.value != false
            ? 'Address is displayed in map'
            : '';
    super.initState();
  }

  @override
  void dispose() {
    formattedAdressController.dispose();
    print('Formatted Address Controller disposed');
    super.dispose();
  }

  /// Builds the location picker interface with a formatted address display
  /// and an interactive map component.
  ///
  /// The interface includes:
  /// - A formatted address text field showing the selected location
  /// - A map view for visual location selection
  /// - Location search functionality
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formatted Address Section with validation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 12), //
                Expanded(
                  child: TextFormField(
                    key: widget.fieldKeys['location'],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Location is required'
                        : null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'No Location Selected', // Gray placeholder text
                      hintStyle: TextStyle(color: Colors.grey[800]),
                    ),
                    controller: formattedAdressController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          /// Interactive map preview section
          /// Tapping this opens the full map location picker with search capabilities
          /// The map uses the Google Maps API for location selection and geocoding
          GestureDetector(
            onTap: () => _openLocationPicker(
              MapLocationPickerConfig(
                bottomCardBuilder:
                    (context, result, address, isLoading, onNext, _) =>
                        Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (result != null)
                        Expanded(
                          child: Text(
                            result.formattedAddress ?? 'Location selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.error),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: () => onNext(),
                      ),
                    ],
                  ),
                ),
                apiKey: Constants.googleMapsApiKey,
                mapStyle: Theme.of(context).brightness == Brightness.dark
                    ? _darkMapStyle
                    : null,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 16),
              height: (MediaQuery.of(context).size.height /
                  2), // Changed height to half of the screen
              width: (MediaQuery.of(context).size.width /
                  2), // Changed width to half of the screen
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (formState.selectedLocation == null
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Text('Select a location'),
                          ),
                        )
                      : Image.network(
                          googleStaticMapWithMarker(
                            formState.selectedLocation!.latitude,
                            formState.selectedLocation!.longitude,
                            8,
                            apiKey: Constants.googleMapsApiKey,
                          ),
                          fit: BoxFit.cover,
                          width: (MediaQuery.of(context).size.width /
                              2), // Updated width here as well
                          height: (MediaQuery.of(context).size.height /
                              2), // Updated height here as well
                        ))),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the full-screen map location picker with search functionality.
  ///
  /// Parameters:
  /// - [config]: Configuration for the map location picker including initial position,
  ///   styling, and callback handlers
  ///
  /// The method handles:
  /// - Opening the map in a new screen
  /// - Updating the selected location when user confirms
  /// - Updating the formatted address display
  /// - Handling navigation back to the form
  Future<void> _openLocationPicker(MapLocationPickerConfig config) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          config: config.copyWith(
            initialPosition:
                formState.selectedLocation ?? const LatLng(37.422, -122.084),
            onNext: (result) {
              if (result != null) {
                setState(() {
                  formState.selectedLocation = LatLng(
                    result.geometry.location.lat,
                    result.geometry.location.lng,
                  );
                  formattedAdressController.text =
                      result.formattedAddress ?? "Address not available";
                  // _formattedAddress =
                  //     result.formattedAddress ?? "Address not available";
                });
              }
              if (context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          searchConfig: SearchConfig(
            apiKey: Constants.googleMapsApiKey,
            searchHintText: "Search for a location",
          ),
        ),
      ),
    );
  }

  /// Custom dark theme style for Google Maps
  /// Provides a dark mode appearance with custom colors for:
  /// - Map geometry and features
  /// - Roads and transit
  /// - Labels and text
  /// - Water bodies
  ///
  /// This style is applied when the app is in dark mode
  final String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#212121" }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#757575" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#212121" }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      { "color": "#757575" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      { "color": "#313131" }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      { "color": "#263c3f" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      { "color": "#2c2c2c" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      { "color": "#212121" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#8a8a8a" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2f3948" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      { "color": "#000000" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#3d3d3d" }
    ]
  }
]
  ''';
}
