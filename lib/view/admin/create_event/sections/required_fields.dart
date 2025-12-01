import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/view/admin/create_event/sections/widgets/event_service_radio_buttons.dart';
import 'package:traxx_wepapp/widgets/date_time_picker.dart';
import 'package:traxx_wepapp/view/admin/create_event/widgets/timezone_chooser.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';
import 'package:traxx_wepapp/utils/static_data.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

/// A widget that displays the required fields for event creation.
/// This includes essential information such as event name, address,
/// capacity, date/time, and other mandatory fields.
class RequiredFields extends StatelessWidget {
  /// Map of form field keys used for form validation and field references.
  /// Keys include: 'eventName', 'address', 'capacity', etc.
  final Map<String, GlobalKey<FormFieldState>> fieldKeys;

  const RequiredFields({
    super.key,
    required this.fieldKeys,
  });

  @override
  Widget build(BuildContext context) {
    /// Get access to the shared event form state
    final EventFormState formState = Get.find<EventFormState>();
    print('EventForm state: ${formState.toString()}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///Event service type radio buttons
        EventServiceRadioButtons(formState: formState),
        AppSpacing.verticalXs(context),

        /// Event name input field
        /// Required field that must not be empty
        TextFormField(
          key: fieldKeys['eventName'],
          controller: formState.nameController,
          decoration: const InputDecoration(
            labelText: 'Event Name *',
            hintText: 'Enter event title',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an event name';
            }
            return null;
          },
        ),
        AppSpacing.verticalXs(context),

        /// Event address/location input field
        /// Required field for specifying where the event will take place
        /// Supports multi-line input for detailed location information
        TextFormField(
          key: fieldKeys['address'],
          controller: formState.addressController,
          decoration: const InputDecoration(
            labelText: 'Address *',
            hintText: 'Enter full location',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an address';
            }
            return null;
          },
        ),
        AppSpacing.verticalXs(context),

        /// Event capacity input field
        /// Numeric input field that only accepts digits
        /// Used to specify the maximum number of attendees allowed
        TextFormField(
          key: fieldKeys['capacity'],
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          controller: formState.capacityController,
          decoration: const InputDecoration(
            labelText: 'Capacity *',
            hintText: 'Maximum number of guests',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter capacity';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        AppSpacing.verticalXs(context),

        /// Event type selection dropdown
        /// Searchable dropdown menu for selecting the type of event
        /// Uses predefined event types from StaticData
        DropdownSearch<String>(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an event type';
            }
            return null;
          },
          items: (filter, loadProps) {
            return StaticData.eventTypes.toList();
          },
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem == null || selectedItem.isEmpty) {
              return Text(
                'Select an event type...',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Text(selectedItem);
          },
          selectedItem: formState.selectedEventType,
          onChanged: (value) {
            formState.selectedEventType = value;
          },
          popupProps: PopupProps.menu(
            searchDelay: Duration(milliseconds: 30),
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search for a event type...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        AppSpacing.verticalXs(context),
        //Timezone chooser widget
        TimezoneChooser(formState: formState),
        AppSpacing.verticalXs(context),

        /// Event date selection widget
        /// Allows user to pick the date for the event
        DateTimePicker(
            initialDateTime: formState.date,
            label: 'Select Event Date',
            onDateTimeChanged: (dateTime) {
              formState.date = dateTime;
            }),
        AppSpacing.verticalXs(context),

        /// Start time selection widget
        /// Allows user to pick when the event begins
        DateTimePicker(
            initialDateTime: formState.startTime != null
                ? DateTime(2023, 1, 1, formState.startTime!.hour,
                    formState.startTime!.minute)
                : null,
            label: 'Select Start Time',
            onDateTimeChanged: (dateTime) {
              if (dateTime != null) {
                formState.startTime = TimeOfDay.fromDateTime(dateTime);
              }
            }),
        AppSpacing.verticalXs(context),

        /// End time selection widget
        /// Allows user to pick when the event ends
        DateTimePicker(
            initialDateTime: formState.endTime != null
                ? DateTime(2023, 1, 1, formState.endTime!.hour,
                    formState.endTime!.minute)
                : null,
            label: 'Select End Time',
            onDateTimeChanged: (dateTime) {
              if (dateTime != null) {
                formState.endTime = TimeOfDay.fromDateTime(dateTime);
              }
            }),
        AppSpacing.verticalXs(context),
        DateTimePicker(
            //Enable dates between start and end date
            initialDateTime: formState.rsvpDeadline,
            label: 'Select RSVP Deadline',
            onDateTimeChanged: (dateTime) {
              formState.rsvpDeadline = dateTime;
            }),
        AppSpacing.verticalXs(context),
      ],
    );
  }
}
