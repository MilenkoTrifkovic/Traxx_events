import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class PaymentCancelledPage extends StatelessWidget {
  const PaymentCancelledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancelled Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                AppText.styledHeadingLarge(
                  context,
                  'Payment Cancelled',
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 16),

                // Message
                AppText.styledBodyLarge(
                  context,
                  'Your payment was cancelled. No charges were made to your account.',
                  color: AppColors.textMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Try Again Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to buy credits
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText.styledBodyLarge(
                      context,
                      'Try Again',
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary Button
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: AppText.styledBodyMedium(
                    context,
                    'Go Back',
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
