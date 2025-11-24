import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/create_event_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/form_step_model.dart';
import 'package:traxx_wepapp/utils/enums/date_time_input_type.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/utils/static_data.dart';
import 'package:traxx_wepapp/widgets/app_date_time_input_field.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/form_step_header.dart';
import 'package:traxx_wepapp/widgets/multi_step_form_widget.dart';

class CreateEventPopupView extends StatefulWidget {
  const CreateEventPopupView({super.key});

  @override
  State<CreateEventPopupView> createState() => _CreateEventPopupViewState();
}

class _CreateEventPopupViewState extends State<CreateEventPopupView> {
  late CreateEventController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = Get.put(CreateEventController());

    // Listen for snackbar messages
    ever(controller.snackBarMessage, (message) {
      print('Snackbar message received: ${message?.message}');
      if (message != null && mounted) {
        // Show appropriate snackbar based on type
        // switch (message.type) {
        //   case SnackBarType.success:
        //     SnackBarUtils.showSuccess(context, message.message);
        //     break;
        //   case SnackBarType.error:
        //     SnackBarUtils.showError(context, message.message);
        //     break;
        //   case SnackBarType.warning:
        //     SnackBarUtils.showInfo(context, message.message);
        //     break;
        // }

        // Clear the message after showing
        controller.clearSnackBarMessage();
      }
    });

    // Listen for navigation
    ever(controller.shouldPop, (shouldPop) {
      if (shouldPop && mounted) {
        popRoute(context);
        controller.clearShouldPop();
      }
    });
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed
    Get.delete<CreateEventController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      content: Padding(
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.xxxl, // 64px on desktop
          verticalPadding: Sizes.xl, // 48px on desktop
        ),
        child: MultiStepFormWidget(
          onSubmit: () => controller.submitEvent(),
          steps: [
            // Step 1: Event Name, Event Type, Date, RSVP Date, Start Time, End Time
            FormStepModel(
              header: const FormStepHeader(
                icon: Icons.upload_file_rounded,
                title: 'Add New Event',
                description: 'Let\'s create your event',
              ),
              onContinue: () => controller.validateStep1(),
              form: Form(
                child: Column(
                  children: [
                    // Event Name
                    Obx(() => AppTextInputField(
                          label: 'Event Name',
                          controller: controller.nameController,
                          errorText: controller.nameError.value.isEmpty
                              ? null
                              : controller.nameError.value,
                        )),

                    // Event Type Dropdown
                    Obx(() => AppDropdownMenu<String>(
                          label: 'Event Type',
                          hintText: 'Select event type',
                          value: controller.selectedEventType.value,
                          errorText: controller.eventTypeError.value.isEmpty
                              ? null
                              : controller.eventTypeError.value,
                          items: StaticData.eventTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.updateEventType(newValue);
                          },
                        )),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Event Date
                        Obx(() => AppDateTimeInputField(
                              label: 'Event Date',
                              inputType: DateTimeInputType.dateOnly,
                              selectedDateTime: controller.selectedDate.value,
                              errorText: controller.dateError.value.isEmpty
                                  ? null
                                  : controller.dateError.value,
                              onChanged: (dateTime) {
                                controller.updateDate(dateTime);
                              },
                            )),

                        // RSVP Deadline
                        Obx(() => AppDateTimeInputField(
                              label: 'RSVP Deadline',
                              inputType: DateTimeInputType.dateOnly,
                              selectedDateTime:
                                  controller.selectedRsvpDeadline.value,
                              errorText:
                                  controller.rsvpDeadlineError.value.isEmpty
                                      ? null
                                      : controller.rsvpDeadlineError.value,
                              onChanged: (dateTime) {
                                controller.updateRsvpDeadline(dateTime);
                              },
                            )),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Start Time
                        Obx(() => AppDateTimeInputField(
                              label: 'Start Time',
                              inputType: DateTimeInputType.timeOnly,
                              selectedDateTime:
                                  controller.selectedStartTime.value != null
                                      ? DateTime(
                                          2023,
                                          1,
                                          1,
                                          controller
                                              .selectedStartTime.value!.hour,
                                          controller
                                              .selectedStartTime.value!.minute)
                                      : null,
                              errorText: controller.startTimeError.value.isEmpty
                                  ? null
                                  : controller.startTimeError.value,
                              onChanged: (dateTime) {
                                controller.updateStartTime(dateTime);
                              },
                            )),

                        // End Time
                        Obx(() => AppDateTimeInputField(
                              label: 'End Time',
                              inputType: DateTimeInputType.timeOnly,
                              selectedDateTime: controller
                                          .selectedEndTime.value !=
                                      null
                                  ? DateTime(
                                      2023,
                                      1,
                                      1,
                                      controller.selectedEndTime.value!.hour,
                                      controller.selectedEndTime.value!.minute)
                                  : null,
                              errorText: controller.endTimeError.value.isEmpty
                                  ? null
                                  : controller.endTimeError.value,
                              onChanged: (dateTime) {
                                controller.updateEndTime(dateTime);
                              },
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Step 2: Description, Dress Code, Special Notes
            FormStepModel(
              header: const FormStepHeader(
                icon: Icons.upload_file_rounded,
                title: 'Add New Event',
                description: 'Let\'s create your event',
              ),
              onContinue: () => controller.validateStep2(),
              form: Form(
                child: Column(
                  children: [
                    // Description
                    AppTextInputField(
                      label: 'Description (Optional)',
                      controller: controller.descriptionController,
                      maxLines: 3,
                    ),

                    // Max Capacity
                    Obx(() => AppTextInputField(
                          label: 'Max Capacity',
                          controller: controller.capacityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          errorText: controller.capacityError.value.isEmpty
                              ? null
                              : controller.capacityError.value,
                        )),

                    // Dress Code
                    AppTextInputField(
                      label: 'Dress Code (Optional)',
                      controller: controller.dressCodeController,
                    ),

                    // Special Notes
                    AppTextInputField(
                      label: 'Special Notes (Optional)',
                      controller: controller.specialNotesController,
                      maxLines: 3,
                    ),

                    // // Hide Host Info Checkbox
                    // Obx(() => CheckboxListTile(
                    //       title: const Text('Hide host information from guests'),
                    //       value: controller.hideHostInfo.value,
                    //       onChanged: (bool? value) {
                    //         controller.hideHostInfo.value = value ?? false;
                    //       },
                    //       controlAffinity: ListTileControlAffinity.leading,
                    //     )),
                    // Cover Image Upload/Preview
                    Obx(() => _buildCoverImageSection(controller, context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build cover image section with upload button or image preview
  Widget _buildCoverImageSection(
      CreateEventController controller, BuildContext context) {
    return Padding(
      padding: AppPadding.vertical(context, paddingType: Sizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cover Image (Optional)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),

          // Show upload button if no image selected
          if (controller.selectedCoverImage.value == null)
            AppPrimaryButton(
              text: 'Upload Cover Image',
              icon: Icons.file_upload,
              width: 360,
              onPressed: () => controller.pickCoverImage(),
            )
          else
            Column(
              children: [
                // Show image preview if image selected
                Container(
                  width: 360,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: controller.selectedCoverImage.value!
                                .readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              } else if (snapshot.hasError) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              } else {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                          )
                        : FutureBuilder<bool>(
                            future:
                                File(controller.selectedCoverImage.value!.path)
                                    .exists(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data == true) {
                                return Image.file(
                                  File(controller
                                      .selectedCoverImage.value!.path),
                                  fit: BoxFit.cover,
                                );
                              } else {
                                return FutureBuilder<Uint8List>(
                                  future: controller.selectedCoverImage.value!
                                      .readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Action buttons for image
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => controller.pickCoverImage(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Change Image'),
                    ),
                    TextButton.icon(
                      onPressed: () => controller.removeCoverImage(),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),

          // Error message if any
          if (controller.coverImageError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                controller.coverImageError.value,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
