import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_already_responded_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_decline_dialog.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_error_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_form_widgets.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_loading_widget.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// RSVP Response Page - Guest's first step in the invitation flow
/// Allows guests to respond Yes or No to event invitation
/// Uses GuestLayoutController for event data (no redundant fetches)
/// 
/// When [readOnly] is true, displays the page in preview mode without controllers or business logic
class RsvpResponsePage extends StatefulWidget {
  final String invitationId;
  final String? token;
  final String?
      eventName; // Optional - will use from GuestLayoutController if available
  final bool readOnly; // If true, displays in preview mode without controllers
  final Event? event; // Required when readOnly is true

  const RsvpResponsePage({
    super.key,
    required this.invitationId,
    this.token,
    this.eventName,
    this.readOnly = false,
    this.event,
  });

  @override
  State<RsvpResponsePage> createState() => _RsvpResponsePageState();
}

class _RsvpResponsePageState extends State<RsvpResponsePage> {
  RsvpResponseController? controller;
  GuestLayoutController? guestController;

  @override
  void initState() {
    super.initState();

    // Skip ALL controller initialization in read-only mode
    // Never call Get.find when readOnly is true
    if (widget.readOnly == true) {
      // Ensure controllers remain null in read-only mode
      controller = null;
      guestController = null;
      debugPrint('✅ RsvpResponsePage: Read-only mode, skipping controller initialization');
      return;
    }

    // Only access controllers in normal (non-readonly) mode
    try {
      // Check if controllers exist before trying to find them
      if (Get.isRegistered<GuestLayoutController>()) {
        guestController = Get.find<GuestLayoutController>();
      }
      
      if (Get.isRegistered<RsvpResponseController>(tag: widget.invitationId)) {
        controller = Get.find<RsvpResponseController>(tag: widget.invitationId);
      }

      // Update event name from GuestLayoutController if available
      if (guestController != null && controller != null) {
        if (guestController!.eventName != null && controller!.eventName == null) {
          controller!.eventName = guestController!.eventName ?? widget.eventName;
        }
      }
    } catch (e) {
      // If controllers don't exist, set to null (shouldn't happen in normal flow)
      debugPrint('⚠️ Controllers not found in RsvpResponsePage: $e');
      controller = null;
      guestController = null;
    }
  }

  @override
  void dispose() {
    // DON'T delete controller - it's managed by the shell route lifecycle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    // Read-only mode: just show the form (no reactive code, no controllers)
    if (widget.readOnly) {
      return _buildRsvpForm(isPhone, readOnly: true);
    }

    // Normal mode: use reactive controllers
    if (controller == null || guestController == null) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    return Obx(() => _buildContent(isPhone));
  }

  /// Route to appropriate state based on controller status
  Widget _buildContent(bool isPhone) {
    if (controller == null) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }
    
    // Loading state
    if (controller!.isLoading.value) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    // Error state (if not already responded)
    if (controller!.error.value != null && !controller!.hasResponded) {
      return RsvpErrorWidget(
        isPhone: isPhone,
        errorMessage: controller!.error.value!,
        onRetry: () => controller!.checkExistingResponse(),
      );
    }

    // Already responded - check completion status and navigate if needed
    if (controller!.hasResponded) {
      // If not attending, show thank you widget
      if (!controller!.isAttending!) {
        return RsvpAlreadyRespondedWidget(
          isPhone: isPhone,
          isAttending: false,
          rsvpSubmittedAt: controller!.rsvpSubmittedAt,
          declineReason: controller!.declineReason,
        );
      }

      // If attending, check if all steps are completed
      if (controller!.isFullyCompleted) {
        // All done - show completion widget
        return RsvpAlreadyRespondedWidget(
          isPhone: isPhone,
          isAttending: true,
          rsvpSubmittedAt: controller!.rsvpSubmittedAt,
          declineReason: controller!.declineReason,
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
  Widget _buildRsvpForm(bool isPhone, {bool readOnly = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with event details
        if (readOnly && widget.event != null)
          RsvpHeaderWidget(
            isPhone: isPhone,
            eventName: widget.event!.name,
            eventDate: widget.event!.date,
            startTime: widget.event!.startTime,
            endTime: widget.event!.endTime,
            eventAddress: widget.event!.address,
            eventType: widget.event!.eventType,
          )
        else if (guestController != null)
          Obx(() => RsvpHeaderWidget(
                isPhone: isPhone,
                eventName: guestController!.eventName ?? widget.eventName,
                eventDate: guestController!.eventDate,
                startTime: guestController!.event.value?.startTime,
                endTime: guestController!.event.value?.endTime,
                eventAddress: guestController!.eventAddress,
                eventType: guestController!.eventType,
              ))
        else
          RsvpHeaderWidget(
            isPhone: isPhone,
            eventName: widget.eventName,
            eventDate: null,
            startTime: null,
            endTime: null,
            eventAddress: null,
            eventType: null,
          ),

        SizedBox(height: AppSpacing.xxxl(context)),

        // Main question card
        RsvpQuestionCard(isPhone: isPhone),

        SizedBox(height: AppSpacing.xl(context)),

        // Action buttons
        _buildActionButtons(isPhone, readOnly: readOnly),

        // Error message (for submission errors) - only show in non-readonly mode
        if (!readOnly && controller != null && controller!.error.value != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md(context)),
            child: RsvpErrorMessage(
              message: controller!.error.value!,
              onClose: () => controller!.clearError(),
            ),
          ),

        SizedBox(height: AppSpacing.xl(context)),

        // Footer note
        RsvpFooterNote(isPhone: isPhone),
      ],
    );
  }

  /// Build Yes/No action buttons
  Widget _buildActionButtons(bool isPhone, {bool readOnly = false}) {
    final isSubmitting = readOnly || controller == null ? false : controller!.isSubmitting.value;

    return Column(
      children: [
        // Yes, I'm attending
        RsvpButton(
          onPressed: readOnly
              ? null
              : (isSubmitting
                  ? null
                  : () async {
                      final success = await controller!.submitAttending();
                      if (success && mounted) {
                        _navigateToGuestCount();
                      }
                    }),
          icon: Icons.check_circle_outline,
          label: 'Yes, I\'m attending',
          isPrimary: true,
          isLoading: isSubmitting,
          isPhone: isPhone,
        ),

        SizedBox(height: AppSpacing.sm(context)),

        // No, I can't make it
        RsvpButton(
          onPressed: readOnly
              ? null
              : (isSubmitting
                  ? null
                  : () => RsvpDeclineDialog.show(
                        context: context,
                        onConfirm: (String? reason) async {
                          final success = await controller!.submitNotAttending(
                            declineReason: reason,
                          );
                          if (success && mounted) {
                            _navigateToThankYou();
                          }
                        },
                      )),
          icon: Icons.cancel_outlined,
          label: 'No, I can\'t make it',
          isPrimary: false,
          isLoading: false,
          isPhone: isPhone,
        ),
      ],
    );
  }

  /// Navigate to guest count page with query parameters
  void _navigateToGuestCount() {
    if (controller == null) return;
    final queryParams = {
      'invitationId': controller!.invitationId!,
      if (controller!.token != null) 'token': controller!.token!,
    };
    pushAndRemoveAllRoute(
      AppRoute.guestCompanions,
      context,
      queryParams: queryParams,
    );
    print('✅ Navigated to /guest-count');
  }

  /// Navigate to companions info page with query parameters
  void _navigateToCompanionsInfo() {
    if (controller == null) return;
    final queryParams = {
      'invitationId': controller!.invitationId!,
      if (controller!.token != null) 'token': controller!.token!,
    };
    pushAndRemoveAllRoute(
      AppRoute.guestCompanionsInfo,
      context,
      queryParams: queryParams,
    );
    print('✅ Navigated to /guest-companions-info');
  }

  /// Navigate to demographics page with query parameters
  void _navigateToDemographics() {
    if (controller == null) return;
    print('token in controller: ${controller!.token}');
    print('token in widget: ${widget.token}');
    final queryParams = {
      'invitationId': controller!.invitationId!,
      if (controller!.token != null) 'token': controller!.token!,
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
    if (controller == null) return;
    final queryParams = {
      'invitationId': controller!.invitationId!,
      if (controller!.token != null) 'token': controller!.token!,
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
    if (controller == null) return;
    final queryParams = {
      'invitationId': controller!.invitationId!,
      if (controller!.token != null) 'token': controller!.token!,
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
    if (controller == null) return;
    final nextStep = controller!.nextIncompleteStep;

    if (nextStep == null) {
      // All steps completed, go to thank you
      _navigateToThankYou();
      return;
    }

    switch (nextStep) {
      case 'companions':
        if (controller!.companionsCount != null &&
            controller!.companionsCount! > 0) {
          // User has selected companion count > 0, go to companions info to fill details
          _navigateToCompanionsInfo();
        } else {
          // User hasn't selected companion count yet, go to guest count page
          _navigateToGuestCount();
        }
        break;
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
