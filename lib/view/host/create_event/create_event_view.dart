import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/create_event_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/host/create_event/sections/cover_image_upload.dart';
import 'package:traxx_wepapp/view/host/create_event/widgets/map_location_picker.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';
import 'sections/action_buttons.dart';
import 'sections/optional_fields.dart';
import 'sections/required_fields.dart';

/// A view that provides a comprehensive form for creating new events.
///
/// This view includes:
/// - Required fields (event name, address, capacity, etc.)
/// - Location picker with map integration
/// - Optional event details
/// - Cover image upload
/// - Save and cancel actions
///
/// The view handles form validation, data persistence, and user navigation.
class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

/// State management class for the CreateEventView.
/// Handles form state, validation, and event creation logic.
class _CreateEventViewState extends State<CreateEventView> {
  /// Global key for the form widget to handle validation
  final _formKey = GlobalKey<FormState>();

  /// State management for the event form using GetX
  final EventFormState _formState = Get.put(EventFormState());

  /// Controller for handling event creation and persistence
  final CreateEventController createEventController =
      Get.put(CreateEventController());

  /// Keys for accessing and validating individual form fields
  /// Used for field-specific validation and auto-scrolling to invalid fields
  final Map<String, GlobalKey<FormFieldState>> _fieldKeys = {
    'eventName': GlobalKey<FormFieldState>(),
    'address': GlobalKey<FormFieldState>(),
    'capacity': GlobalKey<FormFieldState>(),
    'eventType': GlobalKey<FormFieldState>(),
    'timezone': GlobalKey<FormFieldState>(),
    'startDateTime': GlobalKey<FormFieldState>(),
    'endDateTime': GlobalKey<FormFieldState>(),
    'rsvpDeadline': GlobalKey<FormFieldState>(),
    'location': GlobalKey<FormFieldState>(),
  };

  /// Cleans up resources when the widget is disposed
  ///
  /// - Disposes of the form state
  /// - Removes the EventFormState instance from GetX
  @override
  void dispose() {
    _formState.dispose();
    Get.delete<EventFormState>();
    super.dispose();
  }

  /// Builds the event creation form interface
  ///
  /// Creates a scrollable form with:
  /// - A heading
  /// - Required fields section
  /// - Location picker
  /// - Optional fields section
  /// - Cover image upload
  /// - Action buttons
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppPadding.all(context, paddingType: PaddingType.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledHeadingMedium(
            context,
            'Create Event',
          ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RequiredFields(fieldKeys: _fieldKeys),
                LocationPickerScreen(fieldKeys: _fieldKeys),
                OptionalFields(),
                CoverImageUpload(),
                ActionButtons(
                  onSave: _handleSave,
                  onCancel: _handleCancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the event saving process
  ///
  /// This method:
  /// 1. Validates all form fields
  /// 2. Scrolls to the first invalid field if validation fails
  /// 3. Shows a loading indicator during save
  /// 4. Saves the event using the controller
  /// 5. Shows success/error messages
  /// 6. Navigates back on success
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      // Finds first invalid field and scrolls to it
      for (var field in _fieldKeys.keys) {
        if (_fieldKeys[field]?.currentState?.validate() == false) {
          Scrollable.ensureVisible(
            duration: const Duration(milliseconds: 300),
            _fieldKeys[field]!.currentContext!,
            curve: Curves.easeOut,
          );
          break;
        }
      }
      return;
    }

    try {
      showLoadingIndicator();
      await createEventController.saveEvent();
      if (!mounted) return;
      await popRoute(context);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Event is created successfully!');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      SnackBarUtils.showError(context, message);
    } finally {
      hideLoadingIndicator();
    }
  }

  /// Handles the cancellation of event creation
  ///
  /// Shows a confirmation dialog before discarding changes.
  /// If confirmed, navigates back to the previous screen.
  void _handleCancel() {
    Dialogs.showConfirmationDialog(
      context,
      'Are you sure you want to discard all changes?',
      () {
        popRoute(context);
      },
    );
  }
}
