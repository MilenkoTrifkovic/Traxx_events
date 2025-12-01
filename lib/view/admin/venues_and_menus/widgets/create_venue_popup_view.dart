import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:traxx_wepapp/widgets/dialog_step_header.dart';

class CreateVenuePopupView extends StatelessWidget {
  final VenueScreenController controller;
  final VenuesController venuesController;
  const CreateVenuePopupView(
      {super.key, required this.controller, required this.venuesController});
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
                title: 'Create Venue',
                description: 'Let\'s create a new venue.'),
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

            // Image Upload Section
            _buildImageUploadSection(context),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    text: 'Create Venue',
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
        Obx(() {
          if (controller.selectedImage.value != null) {
            return _buildSelectedImage(context);
          } else {
            return AppSecondaryButton(
                width: double.infinity,
                icon: Icons.file_upload,
                iconColor: AppColors.primaryAccent,
                textColor: AppColors.primaryAccent,
                text: 'Upload Venue Photo',
                onPressed: controller.pickImage);
          }
        }),
        AppSpacing.verticalSm(context),

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

  /// Builds the selected image preview
  Widget _buildSelectedImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.borderHover),
      ),
      child: Stack(
        children: [
          //     // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: FutureBuilder<Uint8List>(
              future: controller.selectedImage.value!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                    ),
                    child: Image.memory(
                      snapshot.data!,
                      width: 360,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: controller.removeImage,
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
