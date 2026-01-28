// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:go_router/go_router.dart';
// import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
// import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_demographics_edit_controller.dart';
// import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/demographic_question_widget.dart';
// import 'package:traxx_wepapp/widgets/app_primary_button.dart';
// import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';

// /// Page for editing demographic responses
// class GuestDemographicsEditPage extends StatefulWidget {
//   const GuestDemographicsEditPage({super.key});

//   @override
//   State<GuestDemographicsEditPage> createState() => _GuestDemographicsEditPageState();
// }

// class _GuestDemographicsEditPageState extends State<GuestDemographicsEditPage> {
//   late final GuestDemographicsEditController controller;
//   late final SnackbarMessageController snackbarController;

//   @override
//   void initState() {
//     super.initState();
//     controller = Get.put(GuestDemographicsEditController());
//     snackbarController = Get.find<SnackbarMessageController>();

//     // Get guestId from navigation extra and initialize controller ONCE
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
//       final guestId = extra?['guestId'] as String?;
//       controller.initialize(guestId: guestId);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       if (controller.isLoading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       if (controller.demographicQuestions.isEmpty) {
//         return Center(
//           child: AppText.styledBodyMedium(
//             context,
//             'No demographic questions found',
//             color: AppColors.textMuted,
//           ),
//         );
//       }

//       return Column(
//         children: [
//           // Modern header with gradient background
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.blue[700]!,
//                   Colors.blue[500]!,
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               bottom: false,
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.question_answer,
//                         color: Colors.white,
//                         size: 28,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Demographics',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Fields marked with * are required',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Questions list
//           Expanded(
//             child: Container(
//               color: AppColors.surfaceCard,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Center(
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 900),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Questions list
//                         ...controller.demographicQuestions.map((question) {
//                           return Obx(() => DemographicQuestionWidget(
//                                 question: question,
//                                 currentAnswer:
//                                     controller.formAnswers[question.questionId],
//                                 onAnswerChanged: (answer) {
//                                   controller.updateAnswer(question.questionId, answer);
//                                 },
//                               ));
//                         }).toList(),

//                         const SizedBox(height: 80), // Space for floating button
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Floating action bar
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 20,
//                   offset: const Offset(0, -4),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               top: false,
//               child: Center(
//                 child: Container(
//                   constraints: const BoxConstraints(maxWidth: 900),
//                   padding: const EdgeInsets.all(24),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: AppSecondaryButton(
//                           text: 'Cancel',
//                           onPressed: controller.isSaving.value
//                               ? null
//                               : () => controller.cancel(context),
//                           height: 52,
//                           borderRadius: 12,
//                           enabled: !controller.isSaving.value,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         flex: 2,
//                         child: AppPrimaryButton(
//                           text: controller.isSaving.value
//                               ? 'Saving...'
//                               : 'Save Changes',
//                           icon: controller.isSaving.value
//                               ? null
//                               : Icons.check_circle_outline,
//                           height: 52,
//                           borderRadius: 12,
//                           isLoading: controller.isSaving.value,
//                           onPressed: controller.isSaving.value
//                               ? null
//                               : () async {
//                                   final success =
//                                       await controller.saveResponses();
//                                   if (context.mounted) {
//                                     if (success) {
//                                       snackbarController.showSuccessMessage(
//                                           'Demographics saved successfully');
//                                       Navigator.of(context).pop();
//                                     } else {
//                                       snackbarController.showErrorMessage(
//                                           'Please answer all required questions');
//                                     }
//                                   }
//                                 },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }
