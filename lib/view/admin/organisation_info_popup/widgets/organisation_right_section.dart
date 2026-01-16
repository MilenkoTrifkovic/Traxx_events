import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/content/step_content.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/layout/right_section_container.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/navigation/navigation_buttons.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/navigation/step_indicators.dart';
import 'package:traxx_wepapp/utils/organisation_form_keys.dart';

class OrganisationRightSection extends StatefulWidget {
  const OrganisationRightSection({super.key});

  @override
  State<OrganisationRightSection> createState() =>
      _OrganisationRightSectionState();
}

class _OrganisationRightSectionState extends State<OrganisationRightSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  void _validateAndProceed() {
    final controller = Get.find<OrganisationInfoController>();

    // Validate current step
    bool isValid =
        OrganisationFormKeys.validateCurrentStep(controller.currentStep.value);

    if (isValid) {
      // Special handling for step 0 (sales person ref code)
      if (controller.currentStep.value == 0) {
        _handleSalesPersonStepValidation();
      } else if (controller.isLastStep) {
        _handleFinish();
      } else {
        controller.nextStep();
      }
    }
    // If validation fails, the form will show error messages
  }

  Future<void> _handleSalesPersonStepValidation() async {
    final controller = Get.find<OrganisationInfoController>();

    try {
      // Show loading indicator
      showLoadingIndicator(status: 'Validating sales representative...');

      // Validate and fetch sales person
      final isValid = await controller.validateAndFetchSalesPerson();

      if (isValid) {
        // Proceed to next step
        controller.nextStep();
      }
      // If invalid, validation message is already shown in the form
    } finally {
      // Always hide loading indicator
      hideLoadingIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganisationInfoController>();

    return RightSectionContainer(
      child: Column(
        children: [
          // Form Content - Made Scrollable
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8.0,
              radius: const Radius.circular(4.0),
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16, right: 16),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width < 360
                      ? MediaQuery.of(context).size.width - 32
                      : 360,
                  child: Column(
                    children: [
                      const StepContent(),
                      // Navigation Buttons
                      NavigationButtons(
                        controller: controller,
                        onFinish: _handleFinish,
                        onValidateCurrentStep: _validateAndProceed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Step Indicators
          StepIndicators(controller: controller),
        ],
      ),
    );
  }

  /*  void _handleFinish() async {
    final controller = Get.find<OrganisationInfoController>();

    try {
      // Show loading indicator
      showLoadingIndicator(status: 'Saving company info...');
      print('🏁 Saving organisation through cloud function...');

      // Save organisation through cloud function
      final savedOrganisation = await controller.saveOrganisation();

      // Hide loading indicator
      hideLoadingIndicator();
      pushAndRemoveAllRoute(AppRoute.hostEvents, context);

      // Handle success
      /*   print('✅ Organisation saved successfully!');
      print('📄 Saved organisation data: ${savedOrganisation.toJson()}');
      print('🆔 Assigned organisationId: ${savedOrganisation.organisationId}'); */

      // TODO: Show success message to user
      // TODO: Navigate to next screen
      // TODO: Store organisation data locally if needed

      // Example: Get.snackbar('Success', 'Organisation saved successfully!');
    } catch (e) {
      // Hide loading indicator on error
      hideLoadingIndicator();

      // Handle error
      print('❌ Error saving organisation: $e');

      // TODO: Show error message to user
      // Example: Get.snackbar('Error', 'Failed to save organisation: $e');
    }
  } */

  void _handleFinish() async {
    final controller = Get.find<OrganisationInfoController>();
    final authController = Get.find<AuthController>();

    try {
      showLoadingIndicator(status: 'Saving company info...');
      print('🏁 Saving organisation through cloud function...');

      // Save organisation through cloud function (or attach to existing)
      await controller.saveOrganisation();

      // 🔄 refresh user profile so router sees new org + role
      await authController.loadUserProfile();

      hideLoadingIndicator();

      // Now navigate – router will see companyInfoExists == true
      pushAndRemoveAllRoute(AppRoute.hostEvents, context);
    } catch (e) {
      hideLoadingIndicator();
      print('❌ Error saving organisation: $e');
      /* SnackBarUtils.showError(
        context,
        'Failed to save organisation: $e',
      ); */
    }
  }
}
