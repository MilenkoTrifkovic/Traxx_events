import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/email_verification_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/email_verification_card.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/email_verification_info_panel.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/email_verification_listeners.dart';

//UI should be redefined for this screen
class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(EmailVerificationController());

    return EmailVerificationListeners(
      controller: controller,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: SizedBox.expand(
          child: Stack(
            children: [
              // Background Image
              _buildBackground(),
              // Transparent color overlay
              _buildOverlay(),
              // Content layer above the overlay
              _buildContent(controller, context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build background image
  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/photos/welcome_background.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  /// Build color overlay
  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.primaryAccent.withOpacity(0.6),
      ),
    );
  }

  /// Build main content
  Widget _buildContent(
      EmailVerificationController controller, BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.xl),
        child: Row(
          children: [
            // Left Section - Email Verification Form
            _buildLeftSection(controller, context),
            // Right Section - Info Panel
            const EmailVerificationInfoPanel(),
          ],
        ),
      ),
    );
  }

  /// Build left section with verification card
  Widget _buildLeftSection(
      EmailVerificationController controller, BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: EmailVerificationCard(controller: controller),
        ),
      ),
    );
  }
}
