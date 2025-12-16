import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/dialog_step_header.dart';

class CreateVenuePopupView extends StatelessWidget {
  final VenueScreenController controller;
  final VenuesController venuesController;
  final bool isEditMode;
  const CreateVenuePopupView(
      {super.key,
      required this.controller,
      required this.venuesController,
      this.isEditMode = false});
  // final VenueScreenController controller = VenueScreenController();
  // final VenuesController venuesController = Get.find<VenuesController>();
  @override
  Widget build(BuildContext context) {
    return AppDialog(
        content: SingleChildScrollView(
      child: Padding(
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.xxxl, // 64px on desktop
          verticalPadding: Sizes.xl, // 48px on desktop
        ),
        child: Column(
          children: [
            DialogStepHeader(
                icon: Icons.home_work_outlined,
                title: isEditMode ? 'Edit Venue' : 'Create Venue',
                description: isEditMode
                    ? 'Update the venue details.'
                    : 'Let\'s create a new venue.'),
            _buildVenueForm(context)
          ],
        ),
      ),
    ));
  }

  Widget _buildVenueForm(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalLg(context),

            // Venue Name Field
            AppTextInputField(
              label: 'Venue Name *',
              controller: controller.nameController,
              hintText: 'Enter venue name',
              validator: controller.validateName,
              // maxLength: 100,
            ),

            // Description Field
            AppTextInputField(
              label: 'Description (Optional)',
              controller: controller.descriptionController,
              hintText: 'Enter venue description',
              maxLines: 3,
              validator: controller.validateDescription,
              // maxLength: 500,
            ),
            // Address Field
            Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextInputField(
                        label: 'Street Address *',
                        controller: controller.streetController,
                        hintText: 'Enter your street address...',
                        validator: ValidationHelper.validateAddress,
                      ),
                    ],
                  ),
                ),

                // City Field
                AppTextInputField(
                  label: 'City',
                  controller: controller.cityController,
                  hintText: 'Enter city',
                  validator: ValidationHelper.validateCity,
                ),

                // Country Dropdown
                Obx(() => AppDropdownMenu<String>(
                      label: 'Country',
                      value: controller.selectedCountry.value,
                      hintText: 'Select country',
                      validator: (value) =>
                          ValidationHelper.validateDropdownSelection(
                              value, 'country'),
                      items: USData.countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.selectedCountry.value = newValue;
                        }
                      },
                    )),

                // State and Zip Row
                Row(
                  children: [
                    // State Dropdown
                    Expanded(
                      child: Obx(() => AppDropdownMenu<String>(
                            label: 'State',
                            value: controller.selectedState.value,
                            hintText: 'Select state',
                            validator: (value) =>
                                ValidationHelper.validateDropdownSelection(
                                    value, 'state'),
                            items: USData.states.map((String state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                controller.selectedState.value = newValue;
                              }
                            },
                          )),
                    ),
                    const SizedBox(width: 16),
                    // Zip Field
                    Expanded(
                      child: AppTextInputField(
                        label: 'Zip Code',
                        controller: controller.zipController,
                        hintText: 'Enter zip code',
                        validator: ValidationHelper.validateZipCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Image Upload Section
            _buildImageUploadSection(context),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    text: isEditMode ? 'Update Venue' : 'Create Venue',
                    onPressed: () {
                      if (controller.validateForm()) {
                        popRoute(context, true);
                      }
                    },
                    // text: controller.isCreatingVenue.value
                    //     ? 'Creating...'
                    //     : 'Create Venue',
                    // onPressed: controller.isCreatingVenue.value
                    //     ? null
                    //     : () async {
                    //         final createdVenue =
                    //             await controller.submitForm();
                    //         venuesController.addVenue(createdVenue);
                    //       },
                    // isLoading: controller.isCreatingVenue.value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        AppSecondaryButton(
            width: double.infinity,
            icon: Icons.file_upload,
            iconColor: AppColors.primaryAccent,
            textColor: AppColors.primaryAccent,
            text: 'Upload Venue Photos',
            onPressed: controller.pickImages),

        AppSpacing.verticalSm(context),

        // Selected images grid
        Obx(() {
          if (controller.selectedImages.isNotEmpty) {
            return _buildSelectedImagesGrid(context);
          }
          return const SizedBox.shrink();
        }),

        // Image error display
        Obx(() {
          if (controller.imageError.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                controller.imageError.value!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// Builds the selected images grid
  Widget _buildSelectedImagesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: controller.selectedImages.length,
      itemBuilder: (context, index) {
        return _buildImagePreview(context, index);
      },
    );
  }

  /// Builds a single image preview with remove button
  Widget _buildImagePreview(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.borderHover),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: FutureBuilder<Uint8List>(
              future: controller.selectedImages[index].readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => controller.removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
