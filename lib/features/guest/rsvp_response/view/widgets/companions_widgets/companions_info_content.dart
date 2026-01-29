import 'package:flutter/material.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/models/companion_form_data.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companion_form_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companions_info_header.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companions_info_navigation_buttons.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companions_info_progress_indicator.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// Main content widget for companions information page
class CompanionsInfoContent extends StatelessWidget {
  final List<CompanionFormData> companionForms;
  final int currentIndex;
  final int totalCompanionsCount;
  final int savedCount;
  final int remainingCount;
  final bool readOnly;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmitAll;
  final bool inviteByEmail;

  const CompanionsInfoContent({
    super.key,
    required this.companionForms,
    required this.currentIndex,
    required this.totalCompanionsCount,
    required this.savedCount,
    required this.remainingCount,
    this.readOnly = false,
    this.isSubmitting = false,
    this.onBack,
    this.onNext,
    this.onSubmitAll,
    this.inviteByEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = companionForms.length;

    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.xl,
          verticalPadding: Sizes.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanionsInfoHeader(
              totalCompanionsCount: totalCompanionsCount,
              savedCount: savedCount,
              remainingCount: remainingCount,
            ),
            AppSpacing.verticalLg(context),
            CompanionsInfoProgressIndicator(
              currentIndex: currentIndex,
              totalSteps: totalSteps,
            ),
            AppSpacing.verticalLg(context),
            _buildCurrentForm(context, currentIndex, savedCount),
            AppSpacing.verticalXl(context),
            CompanionsInfoNavigationButtons(
              currentIndex: currentIndex,
              totalSteps: totalSteps,
              readOnly: readOnly,
              isSubmitting: isSubmitting,
              onBack: onBack,
              onNext: onNext,
              onSubmitAll: onSubmitAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentForm(BuildContext context, int index, int savedCount) {
    if (index >= companionForms.length) return const SizedBox.shrink();

    final formData = companionForms[index];

    return CompanionFormWidget(
      formKey: formData.formKey,
      nameController: formData.name,
      emailController: formData.email,
      addressController: formData.address,
      cityController: formData.city,
      selectedCountry: formData.selectedCountry,
      selectedState: formData.selectedState,
      selectedGender: formData.selectedGender,
      companionNumber:
          '${savedCount + index + 1}', // Adjust number to account for already saved
      readOnly: readOnly,
      willAttend: formData.willAttend,
      attendanceDisabled: readOnly || inviteByEmail,
      showAttendanceHint: inviteByEmail,
    );
  }
}
