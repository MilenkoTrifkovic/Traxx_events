import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/email_verification_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';

class EmailVerificationCard extends StatelessWidget {
  final EmailVerificationController controller;

  const EmailVerificationCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Image.asset(
              Constants.lightLogo,
              height: 32,
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Verify your email",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              "We've sent you a verification link. Please check your inbox and click the button to verify your account.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondary,
              ),
            ),
          ),

          // User Email Display
          _buildEmailDisplay(),

          // Continue Button
          _buildContinueButton(),

          const SizedBox(height: 16),

          // Resend Email Button
          _buildResendButton(),

          const SizedBox(height: 32),

          // Divider
          Divider(color: AppColors.borderSubtle),

          const SizedBox(height: 16),

          // Back to Login Button
          _buildBackButton(),

          const SizedBox(height: 16),

          // Auto-check info text
          _buildAutoCheckInfo(),
        ],
      ),
    );
  }

  Widget _buildEmailDisplay() {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.userEmail.value.isNotEmpty
                        ? controller.userEmail.value
                        : 'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildContinueButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : controller.checkEmailVerificationStatus,
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ));
  }

  Widget _buildResendButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed:
                controller.isResendDisabled.value || controller.isLoading.value
                    ? null
                    : controller.resendVerificationEmail,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Resend verification email'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ));
  }

  Widget _buildBackButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : controller.signOutAndReturnToLogin,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to login'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ));
  }

  Widget _buildAutoCheckInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'We\'ll automatically check your verification status every 3 seconds',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
