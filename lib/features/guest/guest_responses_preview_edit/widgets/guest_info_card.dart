// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/models/guest_model.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';

// /// Card displaying guest information
// class GuestInfoCard extends StatelessWidget {
//   final GuestModel guest;

//   const GuestInfoCard({
//     super.key,
//     required this.guest,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.borderSubtle, width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.purple.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     Icons.person,
//                     color: Colors.purple[700],
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 AppText.styledHeadingSmall(
//                   context,
//                   'Your Information',
//                   weight: FontWeight.w600,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _buildInfoRow(context, 'Name', guest.name ?? 'N/A'),
//             const SizedBox(height: 12),
//             _buildInfoRow(context, 'Email', guest.email ?? 'N/A'),
//             const SizedBox(height: 12),
//             _buildInfoRow(context, 'Batch ID', guest.batchId ?? 'N/A'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(BuildContext context, String label, String value) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceCard,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.borderSubtle, width: 1),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: AppText.styledLabelMedium(
//               context,
//               label,
//               weight: FontWeight.w600,
//               color: AppColors.textMuted,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: AppText.styledBodyMedium(context, value),
//           ),
//         ],
//       ),
//     );
//   }
// }
