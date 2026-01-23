import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

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
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                AppText.styledHeadingLarge(
                  context,
                  'Payment Successful!',
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 16),

                // Message
                AppText.styledBodyLarge(
                  context,
                  'Thank you for your purchase. Your credits have been added to your account.',
                  color: AppColors.textMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to buy credits or dashboard
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
                      'Continue',
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Text
                AppText.styledBodySmall(
                  context,
                  'If you have any questions, please email orders@traxx.com',
                  color: AppColors.textMuted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
