// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/models/demographic_response_model.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';

// /// Widget to display demographics response details in read-only mode
// class DemographicsResponseView extends StatelessWidget {
//   final DemographicResponseModel response;

//   /// optionId/value -> label (loaded in controller)
//   final Map<String, String> optionLabels;

//   const DemographicsResponseView({
//     super.key,
//     required this.response,
//     this.optionLabels = const {},
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (response.answers.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: AppText.styledBodyMedium(
//           context,
//           'No responses yet',
//           color: AppColors.textMuted,
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: response.answers.map((answer) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 16.0),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: AppColors.borderSubtle, width: 1.5),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryAccent.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Icon(
//                       Icons.help_outline,
//                       size: 16,
//                       color: AppColors.primaryAccent,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: AppText.styledLabelMedium(
//                       context,
//                       answer.questionText,
//                       weight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: AppColors.surfaceCard,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.borderSubtle, width: 1),
//                 ),
//                 child: AppText.styledBodyMedium(
//                   context,
//                   _formatAnswer(answer),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   String _formatAnswer(DemographicAnswer a) {
//     final v = a.answer;
//     if (v == null) return 'No answer provided';

//     // bool
//     if (v is bool) return v ? 'Yes' : 'No';

//     // string (often old saved optionId)
//     if (v is String) {
//       final key = v.trim();
//       if (key.isEmpty) return 'No answer provided';
//       return optionLabels[key] ?? key;
//     }

//     // map (single selected option)
//     if (v is Map) {
//       final m = Map<String, dynamic>.from(v);

//       final label = (m['label'] ?? m['text'] ?? '').toString().trim();
//       final value = (m['value'] ?? '').toString().trim();
//       final optionId = (m['optionId'] ?? '').toString().trim();
//       final freeText = (m['freeText'] ?? '').toString().trim();

//       final base = label.isNotEmpty
//           ? label
//           : value.isNotEmpty
//               ? value
//               : optionId.isNotEmpty
//                   ? (optionLabels[optionId] ?? optionId)
//                   : m.toString();

//       if (freeText.isNotEmpty) return '$base - $freeText';
//       return base;
//     }

//     // list (checkboxes)
//     if (v is List) {
//       final items = <String>[];

//       for (final item in v) {
//         if (item == null) continue;

//         if (item is Map) {
//           final m = Map<String, dynamic>.from(item);

//           final label = (m['label'] ?? m['text'] ?? '').toString().trim();
//           final value = (m['value'] ?? '').toString().trim();
//           final optionId = (m['optionId'] ?? '').toString().trim();
//           final freeText = (m['freeText'] ?? '').toString().trim();

//           String base = label.isNotEmpty
//               ? label
//               : value.isNotEmpty
//                   ? value
//                   : optionId.isNotEmpty
//                       ? (optionLabels[optionId] ?? optionId)
//                       : m.toString();

//           if (freeText.isNotEmpty) base = '$base - $freeText';
//           items.add(base);
//         } else if (item is String) {
//           final key = item.trim();
//           if (key.isNotEmpty) items.add(optionLabels[key] ?? key);
//         } else if (item is bool) {
//           items.add(item ? 'Yes' : 'No');
//         } else {
//           items.add(item.toString());
//         }
//       }

//       if (items.isEmpty) return 'No answer provided';
//       return items.join(', ');
//     }

//     // fallback
//     return v.toString();
//   }
// }
