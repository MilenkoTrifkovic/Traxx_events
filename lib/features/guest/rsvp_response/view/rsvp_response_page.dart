import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_completed_event_details.dart';
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
  final String? eventName;
  final bool readOnly;
  final Event? event;
  final bool forceDetails;

  const RsvpResponsePage({
    super.key,
    required this.invitationId,
    this.token,
    this.eventName,
    this.readOnly = false,
    this.event,
    this.forceDetails = false,
  });

  @override
  State<RsvpResponsePage> createState() => _RsvpResponsePageState();
}

class _RsvpResponsePageState extends State<RsvpResponsePage> {
  bool _didAutoRoute = false;
  String? _autoRouteInvitationId;
  @override
  void didUpdateWidget(covariant RsvpResponsePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset autoroute when invitation changes
    if (oldWidget.invitationId != widget.invitationId) {
      _didAutoRoute = false;
      _autoRouteInvitationId = null;
    }
  }

  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    // Read-only mode
    if (widget.readOnly) {
      return _buildRsvpForm(
        context,
        isPhone,
        controller: null,
        guestController: null,
        readOnly: true,
      );
    }

    // ✅ ALWAYS resolve fresh controllers for CURRENT invitationId
    final RsvpResponseController? controller =
        Get.isRegistered<RsvpResponseController>(tag: widget.invitationId)
            ? Get.find<RsvpResponseController>(tag: widget.invitationId)
            : null;

    final GuestLayoutController? guestController =
        Get.isRegistered<GuestLayoutController>(tag: widget.invitationId)
            ? Get.find<GuestLayoutController>(tag: widget.invitationId)
            : null;

    // Still not ready → show loader
    if (controller == null || guestController == null) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    // ✅ Ensure RSVP data is loaded once when missing
    if (controller.invitationStatus.value == null &&
        !controller.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // double-check still mounted & still same invitation id
        if (!mounted) return;
        controller.checkExistingResponse();
      });
    }

    return Obx(
        () => _buildContent(context, isPhone, controller, guestController));
  }

  Widget _buildContent(
    BuildContext context,
    bool isPhone,
    RsvpResponseController c,
    GuestLayoutController g,
  ) {
    if (c.isLoading.value) {
      return RsvpLoadingWidget(isPhone: isPhone);
    }

    if (c.error.value != null && !c.hasResponded) {
      return RsvpErrorWidget(
        isPhone: isPhone,
        errorMessage: c.error.value!,
        onRetry: () => c.checkExistingResponse(),
      );
    }

    final status = c.invitationStatus.value;

    if (widget.forceDetails && status != null && status.hasResponded == true) {
      return RsvpCompletedEventDetailsWidget(
        isPhone: isPhone,
        controller: c,
        guestController: g,
      );
    }

    // 1) RSVP not submitted -> show RSVP form
    if (status == null || status.hasResponded != true) {
      return _buildRsvpForm(context, isPhone,
          controller: c, guestController: g);
    }

    // 2) Declined -> show summary/completed widget
    if (status.isConfirmedNotAttending == true) {
      return RsvpCompletedEventDetailsWidget(
        isPhone: isPhone,
        controller: c,
        guestController: g,
      );
    }

    // 3) Attending -> show completed widget ONLY if all steps are done
    if (status.isFullyCompleted == true) {
      return RsvpCompletedEventDetailsWidget(
        isPhone: isPhone,
        controller: c,
        guestController: g,
      );
    }

    // 4) Otherwise resume where left off (companions/demographics/menu)
    final next = status
        .nextIncompleteStep; // expected: 'companions'/'demographics'/'menu'

    final invId = c.invitationId;
    final token = c.token;

    // Prevent routing loop: do it once per invitationId
    final shouldAutoRoute = !_didAutoRoute || _autoRouteInvitationId != invId;

    if (shouldAutoRoute && invId != null && invId.isNotEmpty) {
      _didAutoRoute = true;
      _autoRouteInvitationId = invId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (next == 'companions') {
          pushAndRemoveAllRoute(
            AppRoute.guestCompanions,
            context,
            queryParams: {
              'invitationId': invId,
              if (token != null && token.isNotEmpty) 'token': token,
            },
          );
        } else if (next == 'demographics') {
          pushAndRemoveAllRoute(
            AppRoute.demographics,
            context,
            queryParams: {
              'invitationId': invId,
              if (token != null && token.isNotEmpty) 'token': token,
            },
          );
        } else if (next == 'menu') {
          pushAndRemoveAllRoute(
            AppRoute.menuSelection,
            context,
            queryParams: {
              'invitationId': invId,
              if (token != null && token.isNotEmpty) 'token': token,
            },
          );
        } else {
          // Fallback if next step unknown
          pushAndRemoveAllRoute(
            AppRoute.demographics,
            context,
            queryParams: {
              'invitationId': invId,
              if (token != null && token.isNotEmpty) 'token': token,
            },
          );
        }
      });
    }

    // Show temporary loader while routing
    return RsvpLoadingWidget(isPhone: isPhone);
  }

  Widget _buildRsvpForm(
    BuildContext context,
    bool isPhone, {
    required RsvpResponseController? controller,
    required GuestLayoutController? guestController,
    bool readOnly = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                eventName: guestController.eventName ?? widget.eventName,
                eventDate: guestController.eventDate,
                startTime: guestController.event.value?.startTime,
                endTime: guestController.event.value?.endTime,
                eventAddress: guestController.eventAddress,
                eventType: guestController.eventType,
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
        RsvpQuestionCard(isPhone: isPhone),
        SizedBox(height: AppSpacing.xl(context)),
        _buildActionButtons(context, isPhone, controller),
        if (!readOnly && controller != null && controller.error.value != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md(context)),
            child: RsvpErrorMessage(
              message: controller.error.value!,
              onClose: () => controller.clearError(),
            ),
          ),
        SizedBox(height: AppSpacing.xl(context)),
        RsvpFooterNote(isPhone: isPhone),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isPhone,
    RsvpResponseController? c,
  ) {
    final isSubmitting = c?.isSubmitting.value ?? false;

    return Column(
      children: [
        RsvpButton(
          onPressed: (c == null || isSubmitting)
              ? null
              : () async {
                  final ok = await c.submitAttending();
                  if (ok && mounted) {
                    _navigateToGuestCount(context, c);
                  }
                },
          icon: Icons.check_circle_outline,
          label: 'Yes, I\'m attending',
          isPrimary: true,
          isLoading: isSubmitting,
          isPhone: isPhone,
        ),
        SizedBox(height: AppSpacing.sm(context)),
        RsvpButton(
          onPressed: (c == null || isSubmitting)
              ? null
              : () => RsvpDeclineDialog.show(
                    context: context,
                    onConfirm: (reason) async {
                      final ok =
                          await c.submitNotAttending(declineReason: reason);
                      if (ok && mounted) {
                        _navigateToGuestResponse(context, c);
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

  void _navigateToGuestCount(BuildContext context, RsvpResponseController c) {
    final invId = c.invitationId;
    if (invId == null || invId.isEmpty) return;

    pushAndRemoveAllRoute(
      AppRoute.guestCompanions,
      context,
      queryParams: {
        'invitationId': invId,
        if (c.token != null) 'token': c.token!,
      },
    );
  }

  void _navigateToGuestResponse(
      BuildContext context, RsvpResponseController c) {
    final invId = c.invitationId;
    if (invId == null || invId.isEmpty) return;

    pushAndRemoveAllRoute(
      AppRoute.guestResponse,
      context,
      queryParams: {
        'invitationId': invId,
        if (c.token != null) 'token': c.token!,
      },
    );
  }
}
