// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/features/admin/buy_credits/models/credit_package.dart';
// import 'dart:js' as js;
// import 'dart:html' as html;
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:ui_web' as ui_web;

// class StripePaymentDialog extends StatefulWidget {
//   final CreditPackage package;
//   final String clientSecret;

//   const StripePaymentDialog({
//     super.key,
//     required this.package,
//     required this.clientSecret,
//   });

//   @override
//   State<StripePaymentDialog> createState() => _StripePaymentDialogState();
// }

// class _StripePaymentDialogState extends State<StripePaymentDialog> {
//   String? _errorMessage;
//   late final String _checkoutElementId;
//   bool _isRegistered = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkoutElementId = 'stripe-checkout-${DateTime.now().millisecondsSinceEpoch}';
//     print('🟢 PaymentDialog initialized with clientSecret: ${widget.clientSecret.substring(0, 20)}...');
//     print('🟢 Package: ${widget.package.credits} credits for ${widget.package.priceFormatted}');
    
//     // Initialize Stripe checkout after build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeStripeCheckout();
//     });
//   }

//   void _initializeStripeCheckout() {
//     if (_isRegistered) {
//       print('🟡 View already registered, skipping...');
//       return;
//     }
    
//     try {
//       print('🟢 Initializing Stripe checkout...');
      
//       // Register the view factory for the HTML element
//       // ignore: undefined_prefixed_name
//       ui_web.platformViewRegistry.registerViewFactory(
//         _checkoutElementId,
//         (int viewId) {
//           print('🟢 View factory called for: $_checkoutElementId');
//           final div = html.DivElement()
//             ..id = _checkoutElementId
//             ..style.width = '100%'
//             ..style.height = '100%';
//           return div;
//         },
//       );
      
//       _isRegistered = true;
//       print('🟢 View registered: $_checkoutElementId');
      
//       // Wait a bit for the div to be added to DOM, then initialize Stripe
//       Future.delayed(const Duration(milliseconds: 500), () {
//         print('🟢 Calling JavaScript initStripeCheckout...');
//         // Call JavaScript to initialize Stripe embedded checkout
//         js.context.callMethod('initStripeCheckout', [
//           widget.clientSecret,
//           _checkoutElementId,
//         ]);
//         print('🟢 Stripe checkout initialization requested');
//       });
      
//     } catch (e, stack) {
//       print('🔴 Error initializing Stripe: $e');
//       print('🔴 Stack: $stack');
//       setState(() {
//         _errorMessage = 'Failed to initialize payment form: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('🟢 Building PaymentDialog...');
    
//     try {
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           width: 500,
//           decoration: BoxDecoration(
//             color: AppColors.surface(context),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   AppText.styledHeadingMedium(
//                     context,
//                     'Complete Payment',
//                     weight: FontWeight.w600,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       print('🟢 Close button pressed');
//                       Navigator.of(context).pop(false);
//                     },
//                   ),
//                 ],
//               ),
//             const SizedBox(height: 24),

//             // Package Details
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.surfaceCard,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText.styledBodySmall(
//                         context,
//                         'Credits',
//                         color: AppColors.textMuted,
//                       ),
//                       const SizedBox(height: 4),
//                       AppText.styledHeadingSmall(
//                         context,
//                         '${widget.package.credits}',
//                         weight: FontWeight.w600,
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       AppText.styledBodySmall(
//                         context,
//                         'Total',
//                         color: AppColors.textMuted,
//                       ),
//                       const SizedBox(height: 4),
//                       AppText.styledHeadingSmall(
//                         context,
//                         widget.package.priceFormatted,
//                         weight: FontWeight.w600,
//                         color: AppColors.primaryAccent,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Stripe Checkout Element - Flutter will embed the HTML div here
//             Container(
//               height: 400,
//               decoration: BoxDecoration(
//                 border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: HtmlElementView(viewType: _checkoutElementId),
//             ),
            
//             if (_errorMessage != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppColors.inputError.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: AppText.styledBodySmall(
//                   context,
//                   _errorMessage!,
//                   color: AppColors.inputError,
//                 ),
//               ),
//             ],
            
//             const SizedBox(height: 16),

//             // Secure payment notice
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.lock_outline,
//                   size: 16,
//                   color: AppColors.textMuted,
//                 ),
//                 const SizedBox(width: 8),
//                 AppText.styledBodySmall(
//                   context,
//                   'Secure payment powered by Stripe',
//                   color: AppColors.textMuted,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//     } catch (e, stack) {
//       print('🔴 Error building dialog: $e');
//       print('🔴 Stack: $stack');
//       return Dialog(
//         child: Container(
//           padding: const EdgeInsets.all(24),
//           child: Text('Error loading payment dialog: $e'),
//         ),
//       );
//     }
//   }
// }
