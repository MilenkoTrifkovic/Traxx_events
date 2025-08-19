import 'package:flutter/material.dart';
import 'package:timezone/browser.dart' as tz;
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';
import 'package:dropdown_search/dropdown_search.dart';

/// A widget that provides a searchable dropdown for selecting timezones.
///
/// This widget:
/// - Displays timezones in a user-friendly format (City + GMT offset)
/// - Sorts timezones by their UTC offset
/// - Provides search functionality
/// - Validates timezone selection
/// - Updates the event form state with the selected timezone
class TimezoneChooser extends StatelessWidget {
  /// Reference to the event form state to update timezone selection
  final EventFormState formState;

  /// Creates a TimezoneChooser widget.
  ///
  /// Requires an [EventFormState] instance to manage the selected timezone.
  TimezoneChooser({super.key, required this.formState});

  /// Database of all available timezone locations from the timezone package
  final locations = tz.timeZoneDatabase.locations;

  /// Builds the timezone chooser dropdown widget.
  ///
  /// Creates a searchable dropdown with:
  /// - Validation for required selection
  /// - Sorted timezone list by UTC offset
  /// - Search functionality with instant filtering
  /// - Formatted timezone display with city names and GMT offsets
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownSearch<String>(
          /// Validates that a timezone has been selected
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a timezone';
            }
            return null;
          },

          /// Provides the list of timezone items
          /// Sorts locations by their UTC offset for easier selection
          items: (filter, loadProps) {
            final sortedLocations = locations.entries.toList()
              ..sort((a, b) => a.value.currentTimeZone.offset
                  .compareTo(b.value.currentTimeZone.offset));
            return sortedLocations.map((entry) => entry.key).toList();
          },

          /// Formats the timezone ID into a user-friendly display string
          /// Example: "New York (GMT-5:00)" instead of "America/New_York"
          itemAsString: (id) {
            final timezone = locations[id]!;
            final offset = timezone.currentTimeZone.offset / 3600000;
            final sign = offset >= 0 ? '+' : '';
            final locationParts = id.split('/');
            final displayName = locationParts.length > 1
                ? locationParts[1].replaceAll('_', ' ')
                : locationParts[0].replaceAll('_', ' ');
            return '$displayName (GMT$sign${offset.toInt()}:00)';
          },

          /// Builds the display of the selected timezone in the dropdown
          /// Shows a placeholder when no timezone is selected
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem == null || selectedItem.isEmpty) {
              return Text(
                'Select a timezone...',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Text(selectedItem);
          },

          /// Configures the dropdown popup menu with search functionality
          /// - Adds a search box for filtering timezones
          /// - Sets a small delay for smooth search experience
          /// - Uses a clean, bordered design for the search field
          popupProps: PopupProps.menu(
              searchDelay: Duration(milliseconds: 30),
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search for a timezone...',
                  border: OutlineInputBorder(),
                ),
              ),
              fit: FlexFit.loose),

          /// Updates the event form state with the newly selected timezone
          /// This change is immediately reflected in the form state
          onChanged: (value) {
            formState.selectedTimezone = value;
          },
        ),
      ],
    );
  }
}
