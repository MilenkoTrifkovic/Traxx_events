import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

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
      final bool isFirstStep = controller.isFirstStep;
      final bool hasBackButton = !isFirstStep;
      final bool isLastStep = controller.isLastStep;

      // Special layout for first step (sales person): Skip + Continue buttons
      if (isFirstStep) {
        return Padding(
          padding: AppPadding.vertical(context, paddingType: Sizes.xs),
          child: Row(
            children: [
              // Skip Button
              Expanded(
                child: AppSecondaryButton(
                  text: 'Skip',
                  onPressed: controller.skipSalesPersonStep,
                  height: 44,
                ),
              ),
              const SizedBox(width: 24),
              // Continue Button - only enabled when format is valid
              Expanded(
                child: AppPrimaryButton(
                  text: 'Continue',
                  onPressed: controller.isRefCodeFormatValid.value
                      ? _handleContinueOrFinish
                      : null,
                  enabled: controller.isRefCodeFormatValid.value,
                  height: 44,
                ),
              ),
            ],
          ),
        );
      }

      // Standard layout for other steps
      return Padding(
        padding: AppPadding.vertical(context, paddingType: Sizes.xs),
        child: SizedBox(
          width: double.infinity,
          child: hasBackButton
              ? Row(
                  children: [
                    // Back Button
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Back',
                        onPressed: controller.previousStep,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Continue/Finish Button
                    Expanded(
                      child: AppPrimaryButton(
                        text: isLastStep ? 'Finish' : 'Continue',
                        onPressed: _handleContinueOrFinish,
                        height: 44,
                      ),
                    ),
                  ],
                )
              : AppPrimaryButton(
                  text: isLastStep ? 'Finish' : 'Continue',
                  onPressed: _handleContinueOrFinish,
                  width: double.infinity,
                  height: 44,
                ),
        ),
      );
    });
  }
}
