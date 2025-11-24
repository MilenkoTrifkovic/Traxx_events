import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

/// A form section for optional event details.
/// Includes fields for:
/// - Event link
/// - Instagram handle
/// - Facebook handle
/// - Refund policy
/// - Event description
/// - Dress code
/// - Planner email
///
/// Uses [EventFormState] to manage form data and field controllers.
/// These fields are optional for event creation but provide additional
/// information and social media presence for the event.
class OptionalFields extends StatefulWidget {
  const OptionalFields({
    super.key,
  });

  @override
  State<OptionalFields> createState() => _OptionalFieldsState();
}

class _OptionalFieldsState extends State<OptionalFields> {
  /// Builds the optional fields section with text form fields
  /// connected to the event form state.
  @override
  Widget build(BuildContext context) {
    /// Form state containing the field controllers
    final EventFormState formState = Get.find<EventFormState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        /// Text field for the event description
        /// Allows the event creator to provide a detailed description
        /// of what attendees can expect at the event
        TextFormField(
          controller: formState.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter event description',
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 16),

        /// Text field for specifying the event dress code
        /// Allows hosts to communicate expected attire for attendees
        TextFormField(
          controller: formState.dressCodeController,
          decoration: const InputDecoration(
            labelText: 'Dress Code',
            hintText: 'Enter dress code',
          ),
        ),
        const SizedBox(height: 16),

        /// Text field for the event planner's email address
        /// Used for contact information and can be hidden from guests
        TextFormField(
          controller: formState.plannerEmailController,
          decoration: const InputDecoration(
            labelText: 'Planner Email',
            hintText: 'Enter planner\'s email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),

        /// Checkbox to control the visibility of host's email to guests
        /// When checked, the planner's email will be hidden from event attendees
        CheckboxListTile(
          title: const Text('Hide host email from guests'),
          value: formState.hideHostInfo,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool? value) {
            if (value != null) {
              formState.hideHostInfo = value;
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 16),

        /// Text field for additional event information
        /// Used for providing parking instructions, venue rules,
        /// or any other important information for attendees
        TextFormField(
          controller: formState.specialNotesController,
          decoration: const InputDecoration(
            labelText: 'Special Notes',
            hintText: 'Enter parking instructions, rules, etc.',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
