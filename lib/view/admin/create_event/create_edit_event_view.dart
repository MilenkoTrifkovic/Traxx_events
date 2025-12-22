import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/create_edit_event_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/view/admin/create_event/sections/cover_image_upload.dart';
import 'package:traxx_wepapp/view/admin/create_event/widgets/map_location_picker.dart';
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
class CreateEditEventView extends StatefulWidget {
  const CreateEditEventView({super.key});
  @override
  State<CreateEditEventView> createState() => _CreateEditEventViewState();
}

/// State management class for the CreateEventView.
/// Handles form state, validation, and event creation logic.
class _CreateEditEventViewState extends State<CreateEditEventView> {
  /// Global key for the form widget to handle validation
  final _formKey = GlobalKey<FormState>();

  late final bool isEdit;
  late final Event? event;

  /// State management for the event form using GetX

  // EventFormState _formState = Get.put(EventFormState());
  late EventFormState _formState;
  late HostController hostController;

  /// Controller for handling event creation and persistence
  late final CreateEditEventController createEventController;
  late final SnackbarMessageController snackbarController;

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
    Get.delete<CreateEditEventController>();
    hostController.toggleEditingEvent(false);
    print('EventFormState deleted');
    super.dispose();
  }

  @override
  void initState() {
    hostController = Get.put(HostController());
    snackbarController = Get.find<SnackbarMessageController>();
    isEdit = hostController.isEditingEvent.value;
    if (isEdit) {
      event = hostController.selectedEvent.value;
      print('initState event: ${event.toString()}');
      _formState = Get.put(EventFormState.fromEvent(event!));
      print('initState formState: ${_formState.toString()}');
    } else {
      _formState = Get.put(
        EventFormState(),
      );
    }
    createEventController = Get.put(CreateEditEventController());
    // _formState = Get.put(EventFormState());
    // if (widget.isEdit) {
    //   _formState = EventFormState.fromEvent(widget.event!);
    // }
    super.initState();
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
      padding: AppPadding.all(context, paddingType: Sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledHeadingMedium(
            context,
            isEdit ? 'Edit Event' : 'Create Event',
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
                  onUpdate: _handleUpdate,
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
      final Event savedEvent = await createEventController.saveEvent();
      if (!mounted) return;
      // await popRoute(context);
      pushAndRemoveAllRoute(AppRoute.hostEvents, context);
      // pushAndRemoveAllRoute(AppRoute.eventDetails, context,
      //     extra: savedEvent, urlParam: savedEvent.id);
      if (!mounted) return;
      snackbarController.showSuccessMessage('Event is created successfully!');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      snackbarController.showErrorMessage(message);
    } finally {
      hideLoadingIndicator();
    }
  }

  Future<void> _handleUpdate() async {
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
      await createEventController.updateEvent(event!);
      hostController.toggleEditingEvent(false);
      pushAndRemoveAllRoute(AppRoute.eventDetails, context,
          urlParam: event!.eventId);
      if (!mounted) return;
      hostController.toggleEditingEvent(false);
      if (!mounted) return;
      snackbarController.showSuccessMessage('Event is updated successfully!');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      snackbarController.showErrorMessage(message);
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
        if (hostController.isEditingEvent.value) {
          hostController.toggleEditingEvent(false);
        } else {
          replaceRoute(AppRoute.hostEvents, context);
        }
      },
    );
  }
}
