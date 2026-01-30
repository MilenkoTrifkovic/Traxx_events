// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_responses_preview_controller.dart';
// import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/demographics_response_view.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

/// Guest Demographics View Page
/// Shows demographics responses with option to edit
// class GuestDemographicsViewPage extends StatelessWidget {
//   const GuestDemographicsViewPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<GuestResponsesPreviewController>();

//     return Obx(() {
//       if (controller.isLoading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       final demographicsResponse = controller.demographicsResponse;

//       return SingleChildScrollView(
//         child: Center(
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 900),
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 🆕 Companion Selector (show only if there are companions AND main guest can edit)
//                 if (controller.hasCompanions && controller.canEditCompanionResponses)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 24),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: AppColors.borderSubtle, width: 1.5),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.04),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   Icons.people,
//                                   color: Colors.blue[700],
//                                   size: 24,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               AppText.styledHeadingSmall(
//                                 context,
//                                 'Select Person',
//                                 weight: FontWeight.w600,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Obx(() => Container(
//                             decoration: BoxDecoration(
//                               color: AppColors.surfaceCard,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: AppColors.borderSubtle, width: 1.5),
//                             ),
//                             child: DropdownButtonFormField<String>(
//                               value: controller.selectedGuestId.value,
//                               decoration: InputDecoration(
//                                 border: InputBorder.none,
//                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                                 prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryAccent),
//                               ),
//                               dropdownColor: Colors.white,
//                               icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryAccent),
//                               items: controller.allGuests.map((guest) {
//                                 final label = guest.isCompanion
//                                     ? '${guest.name} (Companion)'
//                                     : '${guest.name} (Main Guest)';
//                                 return DropdownMenuItem(
//                                   value: guest.guestId,
//                                   child: AppText.styledBodyMedium(context, label),
//                                 );
//                               }).toList(),
//                               onChanged: (guestId) {
//                                 if (guestId != null) {
//                                   controller.selectGuest(guestId);
//                                 }
//                               },
//                             ),
//                           )),
//                         ],
//                       ),
//                     ),
//                   ),

//                 // Demographics Response Card
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: AppColors.borderSubtle, width: 1.5),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.04),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: demographicsResponse != null
//                                     ? Colors.green.withOpacity(0.1)
//                                     : Colors.grey.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(
//                                 demographicsResponse != null
//                                     ? Icons.check_circle
//                                     : Icons.question_answer_outlined,
//                                 color: demographicsResponse != null
//                                     ? Colors.green[700]
//                                     : Colors.grey[700],
//                                 size: 24,
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   AppText.styledHeadingSmall(
//                                     context,
//                                     'Demographics',
//                                     weight: FontWeight.w600,
//                                   ),
//                                   const SizedBox(height: 4),
//                                   AppText.styledBodySmall(
//                                     context,
//                                     demographicsResponse != null
//                                         ? 'Your responses have been submitted'
//                                         : 'No responses submitted yet',
//                                     color: AppColors.textMuted,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             AppSecondaryButton(
//                               text: 'Edit',
//                               icon: Icons.edit,
//                               onPressed: () => controller.editDemographics(context),
//                               height: 36,
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                               textColor: AppColors.primaryAccent,
//                               iconColor: AppColors.primaryAccent,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),

//                         // Display actual responses
//                         if (demographicsResponse != null)
//                           DemographicsResponseView(response: demographicsResponse)
//                         else
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: AppColors.surfaceCard,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: AppColors.borderSubtle),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.info_outline,
//                                   color: AppColors.textMuted,
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: AppText.styledBodyMedium(
//                                     context,
//                                     'Click Edit to submit your demographic information',
//                                     color: AppColors.textMuted,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }
