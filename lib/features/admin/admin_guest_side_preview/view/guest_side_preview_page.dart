import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/features/admin/admin_guest_side_preview/controllers/guest_side_preview_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guest_side_preview/widgets/preview_step_content.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

/// Guest side preview page for hosts
/// Shows preview of all guest-facing pages with step selector
class GuestSidePreviewPage extends StatefulWidget {
  final String eventId;

  const GuestSidePreviewPage({
    super.key,
    required this.eventId,
  });

  @override
  State<GuestSidePreviewPage> createState() => _GuestSidePreviewPageState();
}

class _GuestSidePreviewPageState extends State<GuestSidePreviewPage> {
  late final GuestSidePreviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GuestSidePreviewController());
    controller.loadEvent(widget.eventId);
  }

  @override
  void dispose() {
    Get.delete<GuestSidePreviewController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final event = controller.event.value;
      if (event == null) {
        return Center(
          child: Text(
            'Event not found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        );
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            // Cover image section (same as guest pages)
            _buildCoverImage(context, isPhone, isTablet),
            
            // Content section
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1024),
              padding: EdgeInsets.symmetric(
                horizontal: isPhone 
                    ? AppSpacing.lg(context) 
                    : AppSpacing.xl(context),
                vertical: isPhone 
                    ? AppSpacing.xxxl(context) 
                    : AppSpacing.xxxxl(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  _buildStepIndicator(context),
                  
                  AppSpacing.verticalMd(context),
                  
                  // Navigation buttons
                  _buildNavigationButtons(context),
                  
                  AppSpacing.verticalXl(context),
                  
                  // Preview content
                  PreviewStepContent(
                    stepId: controller.selectedStep.value,
                    event: event,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCoverImage(BuildContext context, bool isPhone, bool isTablet) {
    return Obx(() {
      final imageUrl = controller.eventCoverImageUrl.value;
      
      return Container(
        width: double.infinity,
        height: isPhone ? 200 : (isTablet ? 280 : 320),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      );
    });
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.skeletonBase,
            AppColors.skeletonHighlight,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  /// Builds step indicator showing current step name and progress
  Widget _buildStepIndicator(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.availableSteps.indexWhere(
        (s) => s.id == controller.selectedStep.value,
      );
      final totalSteps = controller.availableSteps.length;
      final currentStep = controller.availableSteps.isNotEmpty && currentIndex >= 0
          ? controller.availableSteps[currentIndex]
          : null;

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderInput),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep?.label ?? 'Preview',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step ${currentIndex + 1} of $totalSteps',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Builds Back and Next navigation buttons
  Widget _buildNavigationButtons(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.availableSteps.indexWhere(
        (s) => s.id == controller.selectedStep.value,
      );
      final isFirst = currentIndex <= 0;
      final isLast = currentIndex >= controller.availableSteps.length - 1;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (!isFirst)
            AppSecondaryButton(
              text: 'Back',
              icon: Icons.arrow_back,
              onPressed: () {
                if (currentIndex > 0) {
                  final prevStep = controller.availableSteps[currentIndex - 1];
                  controller.setSelectedStep(prevStep.id);
                }
              },
            )
          else
            const SizedBox.shrink(),
          
          // Next button
          if (!isLast)
            AppPrimaryButton(
              text: 'Next',
              icon: Icons.arrow_forward,
              onPressed: () {
                if (currentIndex < controller.availableSteps.length - 1) {
                  final nextStep = controller.availableSteps[currentIndex + 1];
                  controller.setSelectedStep(nextStep.id);
                }
              },
            )
          else
            const SizedBox.shrink(),
        ],
      );
    });
  }

  // Widget _buildStepSelector(BuildContext context) {
  //   return Obx(() {
  //     return Card(
  //       elevation: 2,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: AppColors.borderInput),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Preview Step',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.black,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             DropdownButtonFormField<String>(
  //               value: controller.selectedStep.value,
  //               decoration: InputDecoration(
  //                 filled: true,
  //                 fillColor: AppColors.surfaceCard,
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                   borderSide: BorderSide(color: AppColors.borderInput),
  //                 ),
  //                 enabledBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                   borderSide: BorderSide(color: AppColors.borderInput),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                   borderSide: BorderSide(color: AppColors.primary, width: 2),
  //                 ),
  //                 contentPadding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 12,
  //                 ),
  //               ),
  //               items: controller.availableSteps.map((step) {
  //                 return DropdownMenuItem<String>(
  //                   value: step.id,
  //                   child: Text(
  //                     step.label,
  //                     style: GoogleFonts.poppins(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 );
  //               }).toList(),
  //               onChanged: (value) {
  //                 if (value != null) {
  //                   controller.setSelectedStep(value);
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   });
  // }
}

