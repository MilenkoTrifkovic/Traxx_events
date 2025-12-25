import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_already_responded_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_decline_dialog.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_error_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_form_widgets.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_loading_widget.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// RSVP Response Page - Guest's first step in the invitation flow
/// Allows guests to respond Yes or No to event invitation
class RsvpResponsePage extends StatefulWidget {
  final String invitationId;
  final String? token;
  final String? eventName;

  const RsvpResponsePage({
    super.key,
    required this.invitationId,
    this.token,
    this.eventName,
  });

  @override
  State<RsvpResponsePage> createState() => _RsvpResponsePageState();
}

class _RsvpResponsePageState extends State<RsvpResponsePage> {
  late final RsvpResponseController controller;

  @override
  void initState() {
    super.initState();
    print('Invitation id in RsvpResponsePage: ${widget.invitationId}');
    
    // Create controller
    controller = Get.put(RsvpResponseController());
    
    // Assign values BEFORE triggering any async operations
    controller.invitationId = widget.invitationId;
    controller.token = widget.token;
    controller.eventName = widget.eventName;
    
    // NOW manually trigger the check (values are already assigned)
    controller.checkExistingResponse();
  }

  @override
  void dispose() {
    Get.delete<RsvpResponseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 20 : (isTablet ? 40 : 60),
            vertical: isPhone ? 24 : 40,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isPhone ? double.infinity : 600,
            ),
            child: Obx(() => _buildContent(isPhone)),
          ),
        ),
      ),
    );
  }

  /// Route to appropriate state based on controller status
  Widget _buildContent(bool isPhone) {
    // Loading state
    if (controller.isLoading.value) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    // Error state (if not already responded)
    if (controller.error.value != null && !controller.hasResponded) {
      return RsvpErrorWidget(
        isPhone: isPhone,
        errorMessage: controller.error.value!,
        onRetry: () => controller.checkExistingResponse(),
      );
    }

    // Already responded - check completion status and navigate if needed
    if (controller.hasResponded) {
      // If not attending, show thank you widget
      if (!controller.isAttending!) {
        return RsvpAlreadyRespondedWidget(
          isPhone: isPhone,
          isAttending: false,
          rsvpSubmittedAt: controller.rsvpSubmittedAt,
          declineReason: controller.declineReason,
        );
      }

      // If attending, check if all steps are completed
      if (controller.isFullyCompleted) {
        // All done - show completion widget
        return RsvpAlreadyRespondedWidget(
          isPhone: isPhone,
          isAttending: true,
          rsvpSubmittedAt: controller.rsvpSubmittedAt,
          declineReason: controller.declineReason,
        );
      }

      // Has responded but not completed all steps - navigate to next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNextIncompleteStep();
      });

      // Show loading while navigating
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    // RSVP form state (hasn't responded yet)
    return _buildRsvpForm(isPhone);
  }

  /// Build the main RSVP form (when guest hasn't responded)
  Widget _buildRsvpForm(bool isPhone) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with event icon and name
        RsvpHeaderWidget(
          isPhone: isPhone,
          eventName: widget.eventName,
        ),

        SizedBox(height: isPhone ? 32 : 48),

        // Main question card
        RsvpQuestionCard(isPhone: isPhone),

        SizedBox(height: isPhone ? 24 : 32),

        // Action buttons
        _buildActionButtons(isPhone),

        // Error message (for submission errors)
        if (controller.error.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: RsvpErrorMessage(
              message: controller.error.value!,
              onClose: () => controller.clearError(),
            ),
          ),

        SizedBox(height: isPhone ? 24 : 32),

        // Footer note
        RsvpFooterNote(isPhone: isPhone),
      ],
    );
  }

  /// Build Yes/No action buttons
  Widget _buildActionButtons(bool isPhone) {
    final isSubmitting = controller.isSubmitting.value;

    return Column(
      children: [
        // Yes, I'm attending
        RsvpButton(
          onPressed: isSubmitting
              ? null
              : () async {
                  final success = await controller.submitAttending();
                  if (success && mounted) {
                    _navigateToDemographics();
                  }
                },
          icon: Icons.check_circle_outline,
          label: 'Yes, I\'m attending',
          isPrimary: true,
          isLoading: isSubmitting,
          isPhone: isPhone,
        ),

        SizedBox(height: isPhone ? 12 : 16),

        // No, I can't make it
        RsvpButton(
          onPressed: isSubmitting
              ? null
              : () => RsvpDeclineDialog.show(
                    context: context,
                    onConfirm: (String? reason) async {
                      final success = await controller.submitNotAttending(
                        declineReason: reason,
                      );
                      if (success && mounted) {
                        _navigateToThankYou();
                      }
                    },
                  ),
          icon: Icons.cancel_outlined,
          label: 'No, I can\'t make it',
          isPrimary: false,
          isLoading: false,
          isPhone: isPhone,
        ),
      ],
    );
  }

  /// Navigate to demographics page with query parameters
  void _navigateToDemographics() {
    print('token in controller: ${controller.token}');
    print ('token in widget: ${widget.token}');
    final queryParams = {
      'invitationId': controller.invitationId!,
      if (controller.token != null) 'token': controller.token!,
    };
    pushAndRemoveAllRoute(
      AppRoute.demographics,
      context,
      queryParams: queryParams,
    );
    print('✅ Navigated to /demographics');
  }

  /// Navigate to menu selection page with query parameters
  void _navigateToMenuSelection() {
    final queryParams = {
      'invitationId': controller.invitationId!,
      if (controller.token != null) 'token': controller.token!,
    };
    pushAndRemoveAllRoute(
      AppRoute.menuSelection,
      context,
      queryParams: queryParams,
    );
    print('✅ Navigated to /menu-selection');
  }

  /// Navigate to thank you page with query parameters
  void _navigateToThankYou() {
    final queryParams = {
      'invitationId': controller.invitationId!,
      if (controller.token != null) 'token': controller.token!,
    };
    pushAndRemoveAllRoute(
      AppRoute.thankYou,
      context,
      queryParams: queryParams,
    );
    print('✅ Navigated to /thank-you');
  }

  /// Navigate to the next incomplete step based on controller status
  void _navigateToNextIncompleteStep() {
    final nextStep = controller.nextIncompleteStep;

    if (nextStep == null) {
      // All steps completed, go to thank you
      _navigateToThankYou();
      return;
    }

    switch (nextStep) {
      case 'demographics':
        _navigateToDemographics();
        break;
      case 'menu':
        _navigateToMenuSelection();
        break;
      default:
        print('⚠️ Unknown step: $nextStep');
        _navigateToThankYou();
    }
  }
}
