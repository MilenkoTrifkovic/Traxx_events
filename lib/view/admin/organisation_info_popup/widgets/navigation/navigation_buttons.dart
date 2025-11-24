import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class NavigationButtons extends StatelessWidget {
  final OrganisationInfoController controller;
  final VoidCallback onFinish;
  final VoidCallback?
      onValidateCurrentStep; // triggers a validation of current step

  const NavigationButtons({
    super.key,
    required this.controller,
    required this.onFinish,
    this.onValidateCurrentStep,
  });

  void _handleContinueOrFinish() {
    // Validate current step before proceeding
    if (onValidateCurrentStep != null) {
      onValidateCurrentStep!();
    } else {
      // If no validation callback, proceed normally
      if (controller.isLastStep) {
        onFinish();
      } else {
        controller.nextStep();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool hasBackButton = !controller.isFirstStep;
      final bool isLastStep = controller.isLastStep;

      return Padding(
        padding: AppPadding.vertical(context, paddingType: Sizes.xs),
        child: SizedBox(
          width: double.infinity,
          child: hasBackButton
              ? Row(
                  children: [
                    // Back Button - takes half width minus 12px
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: controller.previousStep,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textMuted,
                            side: BorderSide(
                              color: AppColors.borderInput,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24), // 24px gap between buttons
                    // Continue/Finish Button - takes half width minus 12px
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _handleContinueOrFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isLastStep ? 'Finish' : 'Continue'),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _handleContinueOrFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isLastStep ? 'Finish' : 'Continue'),
                  ),
                ),
        ),
      );
    });
  }
}
