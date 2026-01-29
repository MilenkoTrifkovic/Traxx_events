import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/models/companion_form_data.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companions_info_content.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/companions_widgets/companions_info_empty_view.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

/// Companions Information Page - Allows guests to enter companion details
///
/// When [readOnly] is true, displays the page in preview mode without controllers or business logic
class CompaignonsInfoPage extends StatefulWidget {
  final String? invitationId;
  final String? token;
  final String? eventName;
  final bool readOnly; // If true, displays in preview mode without controllers
  final Event? event; // Required when readOnly is true

  const CompaignonsInfoPage({
    super.key,
    this.invitationId,
    this.token,
    this.eventName,
    this.readOnly = false,
    this.event,
  });

  @override
  State<CompaignonsInfoPage> createState() => _CompaignonsInfoPageState();
}

class _CompaignonsInfoPageState extends State<CompaignonsInfoPage> {
  RsvpResponseController? controller;
  GuestLayoutController? guestController;
  SnackbarMessageController? snackbarController;

  final List<CompanionFormData> companionForms = [];
  final RxBool isSubmitting = false.obs;
  final RxBool isInitializing = true.obs;
  final RxInt currentStep = 0.obs;

  @override
  void initState() {
    super.initState();

    // ✅ Read-only preview mode: no controllers
    if (widget.readOnly == true) {
      controller = null;
      guestController = null;
      snackbarController = null;

      if (widget.event != null && widget.event!.maxInviteByGuest > 0) {
        final previewCount = widget.event!.maxInviteByGuest.clamp(1, 3);
        for (int i = 0; i < previewCount; i++) {
          final f = CompanionFormData();
          f.name.text = 'Companion ${i + 1}';
          f.email.text = 'companion${i + 1}@example.com';

          // ✅ preview attendance (example)
          // (requires CompanionFormData.willAttend)
          f.willAttend.value = true;

          companionForms.add(f);
        }
      }

      isInitializing.value = false;
      debugPrint(
          '✅ CompaignonsInfoPage: Read-only mode, skipping controller initialization');
      return;
    }

    // ✅ Normal mode
    try {
      final invitationId =
          widget.invitationId ?? Uri.base.queryParameters['invitationId'] ?? '';

      if (Get.isRegistered<RsvpResponseController>(tag: invitationId)) {
        controller = Get.find<RsvpResponseController>(tag: invitationId);
      }

      if (Get.isRegistered<GuestLayoutController>()) {
        guestController = Get.find<GuestLayoutController>();
      }

      if (Get.isRegistered<SnackbarMessageController>()) {
        snackbarController = Get.find<SnackbarMessageController>();
      }

      if (controller != null) {
        _initializeForms();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (!controller!.hasResponded || controller!.isAttending != true) {
            pushAndRemoveAllRoute(
              AppRoute.guestResponse,
              context,
              queryParams: {
                'invitationId': invitationId,
                if (widget.token != null) 'token': widget.token!,
              },
            );
            return;
          }

          if (controller!.companionsCount == null ||
              controller!.companionsCount == 0) {
            pushAndRemoveAllRoute(
              AppRoute.guestCompanions,
              context,
              queryParams: {
                'invitationId': invitationId,
                if (widget.token != null) 'token': widget.token!,
              },
            );
            return;
          }

          // If inviting by email: they still fill names/emails here, then Submit All sends emails
        });
      }
    } catch (e) {
      debugPrint('⚠️ Controllers not found in CompaignonsInfoPage: $e');
      controller = null;
      guestController = null;
      snackbarController = null;
      isInitializing.value = false;
    }
  }

  Future<void> _initializeForms() async {
    if (controller == null) {
      isInitializing.value = false;
      return;
    }

    final companionsCount = controller!.companionsCount ?? 0;
    final isInvitingByEmail =
        controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    int remainingCount = companionsCount;

    if (isInvitingByEmail && companionsCount > 0) {
      try {
        final existingCompanionsCount =
            await controller!.getExistingCompanionCount();
        if (existingCompanionsCount != null) {
          remainingCount = (companionsCount - existingCompanionsCount)
              .clamp(0, companionsCount);
          debugPrint(
              '✅ Found $existingCompanionsCount existing companions, need $remainingCount more');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking existing companions: $e');
        remainingCount = controller!.remainingCompanionsToCreate;
      }
    } else {
      remainingCount = controller!.remainingCompanionsToCreate;
    }

    for (int i = 0; i < remainingCount; i++) {
      final f = CompanionFormData();

      // ✅ default attendance in direct-flow is Yes
      // email-invite flow will ignore this and send null so companion chooses.
      f.willAttend.value = true;

      companionForms.add(f);
    }

    debugPrint('✅ Initialized $remainingCount companion forms');
    isInitializing.value = false;

    if (remainingCount == 0 && companionsCount > 0 && controller != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _navigateToNextStep());
    }
  }

  @override
  void dispose() {
    for (var form in companionForms) {
      form.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return _buildReadOnlyPreview(context);
    }

    if (controller == null || snackbarController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Obx(() {
      if (isInitializing.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final totalCompanionsCount = controller!.companionsCount ?? 0;
      final savedCount = controller!.savedCompanionsCount;
      final remainingCount = companionForms.length;

      if (remainingCount == 0 && totalCompanionsCount > 0) {
        return CompanionsInfoEmptyView(
          readOnly: widget.readOnly,
          savedCount: savedCount,
          totalCount: totalCompanionsCount,
          onContinue: _navigateToNextStep,
        );
      }

      final currentIndex = currentStep.value;
      final inviteByEmail =
          controller!.invitationStatus.value?.isInvitingCompanionsByEmail ==
              true;

      return CompanionsInfoContent(
        companionForms: companionForms, // ✅ now includes willAttend
        currentIndex: currentIndex,
        totalCompanionsCount: totalCompanionsCount,
        savedCount: savedCount,
        remainingCount: remainingCount,
        readOnly: widget.readOnly,
        isSubmitting: isSubmitting.value,
        inviteByEmail: inviteByEmail,
        onBack: _handleBack,
        onNext: _handleNext,
        onSubmitAll: _handleSubmitAll,
      );
    });
  }

  Widget _buildReadOnlyPreview(BuildContext context) {
    final totalSteps = companionForms.length;
    final currentIndex = currentStep.value;

    return CompanionsInfoContent(
      companionForms: companionForms,
      currentIndex: currentIndex,
      totalCompanionsCount: totalSteps,
      savedCount: 0,
      remainingCount: totalSteps,
      readOnly: true,
      isSubmitting: false,
      onBack: null,
      onNext: null,
      onSubmitAll: null,
    );
  }

  void _handleBack() {
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<void> _handleNext() async {
    if (widget.readOnly || controller == null || snackbarController == null)
      return;

    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    if (!formData.validate()) {
      snackbarController!
          .showErrorMessage('Please fill in all required fields correctly');
      return;
    }

    final isInvitingByEmail =
        controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    if (isInvitingByEmail) {
      // ✅ In email-invite flow, companion will answer attendance themselves via /companion-rsvp
      if (currentIndex < companionForms.length - 1) currentStep.value++;
      return;
    }

    // ✅ Direct creation flow
    final otherPendingEmails = <String>[];
    for (int i = 0; i < companionForms.length; i++) {
      if (i != currentIndex && companionForms[i].createdGuestId == null) {
        final email = companionForms[i].email.text.trim();
        if (email.isNotEmpty) otherPendingEmails.add(email);
      }
    }

    if (formData.createdGuestId == null) {
      isSubmitting.value = true;

      final guestId = await controller!.validateAndCreateCompanion(
        name: formData.name.text.trim(),
        email: formData.email.text.trim(),
        // ✅ NEW: attendance captured here
        isAttending: formData.willAttend.value,
        address: formData.address.text.trim().isEmpty
            ? null
            : formData.address.text.trim(),
        city: formData.city.text.trim().isEmpty
            ? null
            : formData.city.text.trim(),
        state: formData.selectedState.value,
        country: formData.selectedCountry.value,
        gender: formData.selectedGender.value,
        otherPendingEmails: otherPendingEmails,
      );

      isSubmitting.value = false;

      if (guestId == null) return;

      formData.createdGuestId = guestId;
      snackbarController!.showSuccessMessage(
          'Companion ${currentIndex + 1} saved successfully!');
    }

    if (currentIndex < companionForms.length - 1) currentStep.value++;
  }

  Future<void> _handleSubmitAll() async {
    if (widget.readOnly || controller == null || snackbarController == null) {
      return;
    }

    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    final isInvitingByEmail =
        controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    // ------------------------------------------------------------
    // 1) Validate forms
    // ------------------------------------------------------------

    if (isInvitingByEmail) {
      // Email-invite flow: every form must be valid (name+email required)
      for (int i = 0; i < companionForms.length; i++) {
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all companion forms (Companion ${i + 1} is incomplete)',
          );
          currentStep.value = i;
          return;
        }
      }
    } else {
      // Proxy flow: validate only unsaved forms
      if (formData.createdGuestId == null && !formData.validate()) {
        snackbarController!
            .showErrorMessage('Please fill in all required fields correctly');
        return;
      }

      for (int i = 0; i < companionForms.length; i++) {
        if (companionForms[i].createdGuestId != null) continue;
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all companion forms (Companion ${i + 1} is incomplete)',
          );
          currentStep.value = i;
          return;
        }
      }
    }

    // ------------------------------------------------------------
    // 2) Validate unique emails ONLY when inviting by email
    // ------------------------------------------------------------

    if (isInvitingByEmail) {
      final emailsToValidate = <String>[];
      for (int i = 0; i < companionForms.length; i++) {
        final email = companionForms[i].email.text.trim();
        if (email.isNotEmpty) emailsToValidate.add(email);
      }

      final emailValidation =
          controller!.validateAllCompanionEmails(emailsToValidate);

      if (emailValidation != null) {
        snackbarController!.showErrorMessage(emailValidation.errorMessage);
        currentStep.value = emailValidation.duplicateIndex;
        return;
      }
    }

    // ------------------------------------------------------------
    // 3) Submit
    // ------------------------------------------------------------

    isSubmitting.value = true;

    try {
      if (isInvitingByEmail) {
        // ✅ Email-invite flow: companion decides attendance later via /companion-rsvp
        final companionData = companionForms
            .map((form) => {
                  'name': form.name.text.trim(),
                  'email': form.email.text.trim(),
                  'address': form.address.text.trim().isEmpty
                      ? null
                      : form.address.text.trim(),
                  'city': form.city.text.trim().isEmpty
                      ? null
                      : form.city.text.trim(),
                  'state': form.selectedState.value,
                  'country': form.selectedCountry.value,
                  'gender': form.selectedGender.value,
                  'maxGuestInvite': 0,
                  'isAttending': null, // ✅ IMPORTANT
                })
            .toList();

        final success = await controller!.sendCompanionInvitations(
          companionData: companionData,
        );

        if (success) {
          snackbarController!.showSuccessMessage(
            'All companion invitations sent successfully!',
          );
          _navigateToNextStep();
        }

        return;
      }

      // ✅ Proxy flow: create companions directly (attendance set by main guest)
      int successCount = 0;
      final failedCompanions = <String>[];

      for (int i = 0; i < companionForms.length; i++) {
        final form = companionForms[i];

        // skip already created
        if (form.createdGuestId != null) {
          successCount++;
          continue;
        }

        // NOTE: we intentionally DO NOT enforce unique emails here (proxy flow)
        final guestId = await controller!.validateAndCreateCompanion(
          name: form.name.text.trim(),
          email: form.email.text.trim(), // can repeat in proxy flow
          isAttending: form.willAttend.value,
          address: form.address.text.trim().isEmpty
              ? null
              : form.address.text.trim(),
          city: form.city.text.trim().isEmpty ? null : form.city.text.trim(),
          state: form.selectedState.value,
          country: form.selectedCountry.value,
          gender: form.selectedGender.value,
          // otherPendingEmails not needed since duplicates allowed
          otherPendingEmails: null,
        );

        if (guestId != null) {
          form.createdGuestId = guestId;
          successCount++;
        } else {
          failedCompanions.add(form.name.text.trim());
        }
      }

      if (successCount == companionForms.length) {
        snackbarController!
            .showSuccessMessage('All companions added successfully!');
        _navigateToNextStep();
      } else if (successCount > 0) {
        snackbarController!.showInfoMessage(
          '$successCount of ${companionForms.length} companions added. '
          'Failed: ${failedCompanions.join(', ')}',
        );
      } else {
        snackbarController!.showErrorMessage(
          'Failed to add companions. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error submitting companions: $e');
      snackbarController
          ?.showErrorMessage('An error occurred. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _navigateToNextStep() async {
    if (widget.readOnly || controller == null) return;

    try {
      final invitationData = await controller!.getLatestInvitationData();
      if (invitationData == null) {
        debugPrint('⚠️ Invitation not found, using fallback navigation');
        _navigateToFallback();
        return;
      }

      final token = controller!.token ?? '';

      final flowState = ResponseFlowState.fromInvitation(
        invitationData,
        token,
        invitationIdOverride: controller!.invitationId!,
      );

      final nextStep = flowState.getNextStep();
      final nextUrl = nextStep.buildUrl(controller!.invitationId!, token);

      debugPrint(
        '✅ Navigating to next step: ${nextStep.step}, companionIndex: ${nextStep.companionIndex}, url: $nextUrl',
      );

      context.go(nextUrl);
    } catch (e) {
      debugPrint('❌ Error determining next step: $e');
      _navigateToFallback();
    }
  }

  void _navigateToFallback() {
    if (widget.readOnly || controller == null) return;

    if (controller!.requiresDemographics && !controller!.hasDemographics) {
      context.go(
        '/demographics?invitationId=${Uri.encodeComponent(controller!.invitationId!)}'
        '&token=${Uri.encodeComponent(controller!.token ?? '')}',
      );
      return;
    }

    if (!controller!.hasMenuSelection) {
      context.go(
        '/menu-selection?invitationId=${Uri.encodeComponent(controller!.invitationId!)}'
        '&token=${Uri.encodeComponent(controller!.token ?? '')}',
      );
      return;
    }

    context.go(
        '/thank-you?invitationId=${Uri.encodeComponent(controller!.invitationId!)}');
  }
}
