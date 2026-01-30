// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/widgets/app_primary_button.dart';

// /// Card with action buttons for managing responses
// class ResponseActionsCard extends StatelessWidget {
//   final void Function(BuildContext) onEditRsvp;
//   final void Function(BuildContext) onEditDemographics;
//   final void Function(BuildContext) onEditMenuSelection;

//   const ResponseActionsCard({
//     super.key,
//     required this.onEditRsvp,
//     required this.onEditDemographics,
//     required this.onEditMenuSelection,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Manage Your Response',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'You can view and edit your RSVP, demographics, and menu selections below.',
//             ),
//             const SizedBox(height: 24),

//             SizedBox(
//               width: double.infinity,
//               child: AppPrimaryButton(
//                 text: 'Edit RSVP Response',
//                 onPressed: () => onEditRsvp(context),
//               ),
//             ),
//             const SizedBox(height: 12),

//             SizedBox(
//               width: double.infinity,
//               child: AppPrimaryButton(
//                 text: 'Edit Demographics',
//                 onPressed: () => onEditDemographics(context),
//               ),
//             ),
//             const SizedBox(height: 12),

//             SizedBox(
//               width: double.infinity,
//               child: AppPrimaryButton(
//                 text: 'Edit Menu Selection',
//                 onPressed: () => onEditMenuSelection(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
