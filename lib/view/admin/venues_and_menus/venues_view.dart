import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_card.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'dart:typed_data';

/// A screen that displays the venue management interface.
///
/// This screen includes:
/// - Form for creating new venues
/// - Image picker for venue photos
/// - Venue list display (commented out for separate controller)
class VenuesView extends StatefulWidget {
  const VenuesView({super.key});

  @override
  State<VenuesView> createState() => _VenuesViewState();
}

class _VenuesViewState extends State<VenuesView> {
  late VenueScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VenueScreenController());

    // Listen for messages and show snackbar
    // ever(controller.message, (message) {
    //   if (message != null && context.mounted) {
    //     if (message.type == SnackBarType.success) {
    //       SnackBarUtils.showSuccess(context, message.message);
    //     } else {
    //       SnackBarUtils.showError(context, message.message);
    //     }

    //     // Clear message after showing
    //     controller.clearMessage();
    //   }
    // });
  }

  // Access the global VenuesController
  final venuesController = Get.find<VenuesController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          // padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVenueForm(context),
              AppSpacing.verticalLg(context),
              _buildVenuesListSection(context, venuesController),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the venue creation form
  Widget _buildVenueForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.0),
        // border: Border.all(color: AppColors.borderHover),
      ),
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
              maxLength: 100,
            ),

            AppSpacing.verticalMd(context),

            // Description Field
            AppTextInputField(
              label: 'Description (Optional)',
              controller: controller.descriptionController,
              hintText: 'Enter venue description',
              maxLines: 3,
              validator: controller.validateDescription,
              maxLength: 500,
            ),

            AppSpacing.verticalMd(context),

            // Image Upload Section
            _buildImageUploadSection(context),

            AppSpacing.verticalLg(context),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    text: 'Clear Form',
                    onPressed: controller.clearForm,
                  ),
                ),
                AppSpacing.horizontalMd(context),
                Expanded(
                  child: Obx(() => AppPrimaryButton(
                        text: controller.isCreatingVenue.value
                            ? 'Creating...'
                            : 'Create Venue',
                        onPressed: controller.isCreatingVenue.value
                            ? null
                            : () async {
                                final createdVenue =
                                    await controller.submitForm();
                                venuesController.addVenue(createdVenue);
                              },
                        isLoading: controller.isCreatingVenue.value,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal list of venue cards
  Widget _buildVenuesListSection(
      BuildContext context, VenuesController venuesController) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: venuesController.venues.length,
      itemBuilder: (context, index) {
        final venue = venuesController.venues[index];
        return Padding(
          padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
          child: VenueCard(
            venue: venue,
            onTap: () {
              // controller.selectedEvent.value = event;
              // eventController.setSelectedEvent(event);
              // if (authController.userRole.value == UserRole.admin) {
              //   pushAndRemoveAllRoute(AppRoute.eventDetails, context,
              //       urlParam: event.eventId);
              // } else {
              //   pushRoute(AppRoute.guestEventDetails, context,
              //       urlParam: event.eventId, extra: event);
              // }
            },
          ),
        );
      },
    );
    // return Container(
    //   width: double.infinity,
    //   padding: const EdgeInsets.all(24.0),
    //   decoration: BoxDecoration(
    //     color: AppColors.white,
    //     borderRadius: BorderRadius.circular(8.0),
    //     border: Border.all(color: AppColors.borderHover),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       AppSpacing.verticalMd(context),
    //       Obx(() {
    //         final venues = venuesController.venues;
    //         if (venues.isEmpty) {
    //           return Center(
    //             child: Padding(
    //               padding: const EdgeInsets.all(32.0),
    //               child: Text(
    //                 'No venues found.',
    //                 style: TextStyle(
    //                   color: AppColors.secondary,
    //                   fontStyle: FontStyle.italic,
    //                 ),
    //               ),
    //             ),
    //           );
    //         }
    //         return SizedBox(
    //           height: 180,
    //           child: ListView.builder(
    //             scrollDirection: Axis.horizontal,
    //             itemCount: venues.length,
    //             itemBuilder: (context, index) {
    //               final venue = venues[index];
    //               return _buildVenueCard(context, venue);
    //             },
    //           ),
    //         );
    //       }),
    //     ],
    //   ),
    // );
  }

  /// Builds a single horizontal venue card
  Widget _buildVenueCard(BuildContext context, venue) {
    return InkWell(
      onTap: () {
        pushAndRemoveAllRoute(AppRoute.hostVenueDetails, context,
            urlParam: venue.venueID);
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.fofofo,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.borderHover),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.styledHeadingSmall(
              context,
              venue.name ?? '-',
            ),
            AppSpacing.verticalSm(context),
            Text(
              venue.description ?? 'No description',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              'ID: ${venue.venueID ?? '-'}',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the image upload section
  Widget _buildImageUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodyLarge(
          context,
          'Venue Photo (Optional)',
          weight: FontWeight.w600,
        ),

        AppSpacing.verticalSm(context),

        Obx(() {
          if (controller.selectedImage.value != null) {
            return _buildSelectedImage(context);
          } else {
            return _buildImagePicker(context);
          }
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

  /// Builds the image picker widget
  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: controller.pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.fofofo,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
              color: AppColors.borderHover, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: AppColors.secondary,
            ),
            AppSpacing.verticalSm(context),
            AppText.styledBodyMedium(
              context,
              'Click to upload venue photo',
              color: AppColors.secondary,
            ),
            AppSpacing.verticalXs(context),
            AppText.styledBodySmall(
              context,
              'Supported formats: JPEG, PNG',
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
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
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: FutureBuilder<Uint8List>(
              future: controller.selectedImage.value!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.fofofo,
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
