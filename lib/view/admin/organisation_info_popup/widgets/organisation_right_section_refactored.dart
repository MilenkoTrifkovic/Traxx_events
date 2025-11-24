// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:traxx_wepapp/controller/host_controllers/organisation_info_controller.dart';
// import 'package:traxx_wepapp/utils/loader.dart';
// import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
// import 'package:traxx_wepapp/utils/navigation/routes.dart';
// import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/content/step_content.dart';
// import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/layout/right_section_container.dart';
// import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/navigation/navigation_buttons.dart';
// import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/navigation/step_indicators.dart';
// import 'package:traxx_wepapp/utils/organisation_form_keys.dart';
// import 'package:traxx_wepapp/widgets/multi_step_form_widget.dart';

// /// Refactored OrganisationRightSection using the reusable MultiStepFormWidget
// class OrganisationRightSectionRefactored extends StatelessWidget {
//   const OrganisationRightSectionRefactored({super.key});

//   Future<void> _handleFinish(OrganisationInfoController controller, BuildContext context) async {
//     try {
//       // Show loading indicator
//       showLoadingIndicator(status: 'Saving company info...');
//       print('🏁 Saving organisation through cloud function...');

//       // Save organisation through cloud function
//       final savedOrganisation = await controller.saveOrganisation();

//       // Hide loading indicator
//       hideLoadingIndicator();
//       pushAndRemoveAllRoute(AppRoute.hostEvents, context);

//       // Handle success
//       print('✅ Organisation saved successfully!');
//       print('📄 Saved organisation data: ${savedOrganisation.toJson()}');
//       print('🆔 Assigned organisationId: ${savedOrganisation.organisationId}');

//     } catch (e) {
//       // Hide loading indicator on error
//       hideLoadingIndicator();
//       print('❌ Error saving organisation: $e');
//       rethrow; // Let the MultiStepFormWidget handle error display
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<OrganisationInfoController>();

//     return RightSectionContainer(
//       child: MultiStepFormWidget<OrganisationInfoController>(
//         controller: controller,
        
//         // Controller interface functions
//         getCurrentStep: (controller) => controller.currentStep.value,
//         isLastStep: (controller) => controller.isLastStep,
//         nextStep: (controller) => controller.nextStep(),
//         previousStep: (controller) => controller.previousStep(),
        
//         // Validation function
//         validateCurrentStep: (currentStep) => 
//             OrganisationFormKeys.validateCurrentStep(currentStep),
        
//         // Completion handler
//         onFinish: (controller) => _handleFinish(controller, context),
        
//         // UI Components
//         stepContent: const StepContent(),
//         stepIndicators: StepIndicators(controller: controller),
        
//         // Optional: Custom navigation buttons (if you want to keep the existing ones)
//         navigationButtons: NavigationButtons(
//           controller: controller,
//           onFinish: () => _handleFinish(controller, context),
//           onValidateCurrentStep: () {
//             // This callback will be handled by the MultiStepFormWidget
//           },
//         ),
//       ),
//     );
//   }
// }