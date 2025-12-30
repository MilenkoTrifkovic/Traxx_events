import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

/// Navigation buttons widget for companions information page
class CompanionsInfoNavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final bool readOnly;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmitAll;

  const CompanionsInfoNavigationButtons({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    this.readOnly = false,
    this.isSubmitting = false,
    this.onBack,
    this.onNext,
    this.onSubmitAll,
  });

  @override
  Widget build(BuildContext context) {
    final isFirstStep = currentIndex == 0;
    final isLastStep = currentIndex == totalSteps - 1;

    // In read-only mode, disable all buttons
    if (readOnly) {
      return Row(
        children: [
          Expanded(
            child: AppSecondaryButton(
              onPressed: null,
              text: 'Back',
            ),
          ),
          AppSpacing.horizontalMd(context),
          Expanded(
            child: AppPrimaryButton(
              onPressed: null,
              text: isLastStep ? 'Submit All' : 'Next',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Back button (disabled on first step)
        Expanded(
          child: AppSecondaryButton(
            onPressed: (isFirstStep || isSubmitting) ? null : onBack,
            text: 'Back',
          ),
        ),
        AppSpacing.horizontalMd(context),
        // Next/Submit button
        Expanded(
          child: AppPrimaryButton(
            onPressed: isSubmitting
                ? null
                : () => isLastStep ? onSubmitAll?.call() : onNext?.call(),
            text: isSubmitting
                ? 'Saving...'
                : isLastStep
                    ? 'Submit All'
                    : 'Next',
          ),
        ),
      ],
    );
  }
}

