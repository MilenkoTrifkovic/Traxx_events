// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/helper/app_padding.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';
// import 'package:traxx_wepapp/theme/constants.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/utils/enums/sizes.dart';
// import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
// import 'package:traxx_wepapp/utils/navigation/routes.dart';
// import 'package:traxx_wepapp/widgets/section_devider.dart';

// class EmailValidationView extends StatelessWidget {
//   const EmailValidationView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       backgroundColor: Colors.transparent,
//       body: SizedBox.expand(
//         child: Stack(
//           children: [
//             // Background Image
//             Positioned.fill(
//               child: Image.asset(
//                 'assets/photos/welcome_background.jpg',
//                 fit: BoxFit.cover,
//               ),
//             ),
//             // Transparent color overlay
//             Positioned.fill(
//               child: Container(
//                 color: AppColors.primaryAccent.withOpacity(0.6),
//               ),
//             ),
//             // Content layer above the overlay
//             Positioned.fill(
//               child: Padding(
//                 padding: AppPadding.all(context, paddingType: Sizes.xl),
//                 child: Row(
//                   children: [
//                     // Left Section - Email Verification
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.5,
//                       child: Container(
//                         margin: EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(
//                               0.95), // Semi-transparent white background
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                               spreadRadius: 2,
//                               offset: Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: EmailVerificationScreen(
//                             actionCodeSettings: ActionCodeSettings(
//                               url: 'https://traxx-e1232.web.app/welcome',
//                               handleCodeInApp: false,
//                             ),
//                             actions: [
//                               EmailVerifiedAction(() {
//                                 pushAndRemoveAllRoute(
//                                     AppRoute.hostEvents, context);
//                               }),
//                               AuthCancelledAction((context) {
//                                 FirebaseUIAuth.signOut(context: context);
//                                 pushAndRemoveAllRoute(
//                                     AppRoute.welcome, context);
//                               }),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Right Section - Custom Content
//                     Expanded(
//                       child: Padding(
//                         padding:
//                             AppPadding.left(context, paddingType: Sizes.xl),
//                         child: Container(
//                           color: Colors.transparent,
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.mark_email_read_outlined,
//                                 size: 80,
//                                 color: AppColors.white.withOpacity(0.9),
//                               ),
//                               SizedBox(height: 24),
//                               AppText.styledHeadingLarge(
//                                 family: Constants.font2,
//                                 weight: FontWeight.bold,
//                                 context,
//                                 'Check Your Email',
//                                 color: AppColors.white,
//                               ),
//                               SectionDivider(
//                                 height: 30,
//                                 thickness: 2,
//                                 color: AppColors.white,
//                               ),
//                               AppText.styledHeadingMedium(
//                                 weight: FontWeight.w500,
//                                 context,
//                                 'Verify your email address to access your Trax Event dashboard and start creating amazing events.',
//                                 color: AppColors.white,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
