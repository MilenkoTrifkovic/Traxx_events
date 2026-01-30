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
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

class CompaignonsInfoPage extends StatefulWidget {
  final String? invitationId;
  final String? token;
  final String? eventName;
  final bool readOnly;
  final Event? event;

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

  String get _invId =>
      (widget.invitationId ?? Uri.base.queryParameters['invitationId'] ?? '')
          .trim();
  int _companionsTarget = 0; // how many companions user selected
  int _savedBase = 0;

  @override
  void initState() {
    super.initState();

    // ✅ Read-only preview mode
    if (widget.readOnly == true) {
      controller = null;
      guestController = null;
      snackbarController = null;

      if (widget.event != null && widget.event!.maxInviteByGuest > 0) {
        final previewCount = widget.event!.maxInviteByGuest.clamp(1, 3);
        for (int i = 0; i < previewCount; i++) {
          final f = CompanionFormData();
          f.name.text = 'Guest ${i + 1}';
          f.email.text = 'guest${i + 1}@example.com';
          f.willAttend.value = true;
          companionForms.add(f);
        }
      }

      isInitializing.value = false;
      return;
    }

    final invitationId =
        widget.invitationId ?? Uri.base.queryParameters['invitationId'] ?? '';

    controller = Get.isRegistered<RsvpResponseController>(tag: invitationId)
        ? Get.find<RsvpResponseController>(tag: invitationId)
        : null;

    snackbarController = Get.isRegistered<SnackbarMessageController>()
        ? Get.find<SnackbarMessageController>()
        : null;

    if (controller == null) {
      isInitializing.value = false;
      return;
    }

    _initializeForms(invitationId);
  }

  Future<void> _initializeForms(String invitationId) async {
    try {
      // ✅ Use latest invitation so counts are accurate
      final inv = await controller!.getLatestInvitationData();
      final comps = (inv?['companions'] as List?) ?? const [];
      _savedBase = comps.length;

      _companionsTarget = controller!.companionsCount ?? 0;

      final remaining =
          (_companionsTarget - _savedBase).clamp(0, _companionsTarget);

      companionForms.clear();
      for (int i = 0; i < remaining; i++) {
        final f = CompanionFormData();
        f.willAttend.value = true; // default
        companionForms.add(f);
      }
    } finally {
      isInitializing.value = false;
    }

    // ✅ If nothing to fill, go next
    if (companionForms.isEmpty && _companionsTarget > 0) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _navigateToNextStep());
    }
  }

  void _handleBack() {
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<void> _handleNext() async {
    if (widget.readOnly || controller == null || snackbarController == null) {
      return;
    }

    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    if (!formData.validate()) {
      snackbarController!
          .showErrorMessage('Please fill in all required fields correctly');
      return;
    }

    final isInvitingByEmail = controller!.isInvitingByEmail;

    // ✅ In invite-by-email mode: just validate duplicates early and move next
    if (isInvitingByEmail) {
      final email = formData.email.text.trim();
      if (email.isNotEmpty) {
        final otherEmails = <String>[];
        for (int i = 0; i < companionForms.length; i++) {
          if (i == currentIndex) continue;
          final e = companionForms[i].email.text.trim();
          if (e.isNotEmpty) otherEmails.add(e);
        }

        final err = controller!.validateCompanionEmail(
          email,
          otherPendingEmails: otherEmails,
        );
        if (err != null) {
          snackbarController!.showErrorMessage(err);
          return;
        }
      }

      if (currentIndex < companionForms.length - 1) currentStep.value++;
      return;
    }

    // ✅ Proxy flow: create companion on Next (as before)
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
        isAttending:
            formData.willAttend.value, // ✅ attendance comes from this page
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
        'Guest ${currentIndex + 1} saved successfully!',
      );
    }

    if (currentIndex < companionForms.length - 1) currentStep.value++;
  }

  Future<void> _handleSubmitAll() async {
    if (widget.readOnly || controller == null || snackbarController == null) {
      return;
    }

    final isInvitingByEmail = controller!.isInvitingByEmail;

    // ------------------------------------------------------------
    // 1) Validate forms
    // ------------------------------------------------------------
    if (isInvitingByEmail) {
      for (int i = 0; i < companionForms.length; i++) {
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all guest forms (Guest ${i + 1} is incomplete)',
          );
          currentStep.value = i;
          return;
        }
      }
    } else {
      for (int i = 0; i < companionForms.length; i++) {
        if (companionForms[i].createdGuestId != null) continue;
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all guest forms (Guest ${i + 1} is incomplete)',
          );
          currentStep.value = i;
          return;
        }
      }
    }

    // ------------------------------------------------------------
    // 2) Validate unique emails ONLY for invite-by-email
    // ------------------------------------------------------------
    if (isInvitingByEmail) {
      final emails = companionForms
          .map((f) => f.email.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final v = controller!.validateAllCompanionEmails(emails);
      if (v != null) {
        snackbarController!.showErrorMessage(v.errorMessage);
        currentStep.value = v.duplicateIndex;
        return;
      }
    }

    // ------------------------------------------------------------
    // 3) Submit
    // ------------------------------------------------------------
    isSubmitting.value = true;

    try {
      if (isInvitingByEmail) {
        // ✅ Invite-by-email: still SAVE attendance here (NOT null)
        final companionData = companionForms
            .map((f) => {
                  'name': f.name.text.trim(),
                  'email': f.email.text.trim(),
                  'address': f.address.text.trim().isEmpty
                      ? null
                      : f.address.text.trim(),
                  'city':
                      f.city.text.trim().isEmpty ? null : f.city.text.trim(),
                  'state': f.selectedState.value,
                  'country': f.selectedCountry.value,
                  'gender': f.selectedGender.value,
                  'maxGuestInvite': 0,

                  // ✅ IMPORTANT: attendance comes from THIS page now
                  'isAttending': f.willAttend.value,
                })
            .toList();

        final success = await controller!
            .sendCompanionInvitations(companionData: companionData);

        if (success) {
          snackbarController!.showSuccessMessage(
            'All guest invitations sent successfully!',
          );
          await _navigateToNextStep();
        }
        return;
      }

      // ✅ Proxy flow: create companions directly
      int successCount = 0;
      final failed = <String>[];

      for (final f in companionForms) {
        if (f.createdGuestId != null) {
          successCount++;
          continue;
        }

        final guestId = await controller!.validateAndCreateCompanion(
          name: f.name.text.trim(),
          email: f.email.text.trim(),
          isAttending: f.willAttend.value,
          address: f.address.text.trim().isEmpty ? null : f.address.text.trim(),
          city: f.city.text.trim().isEmpty ? null : f.city.text.trim(),
          state: f.selectedState.value,
          country: f.selectedCountry.value,
          gender: f.selectedGender.value,
          otherPendingEmails: null, // duplicates allowed in proxy mode
        );

        if (guestId != null) {
          f.createdGuestId = guestId;
          successCount++;
        } else {
          failed.add(f.name.text.trim());
        }
      }

      if (successCount == companionForms.length) {
        snackbarController!
            .showSuccessMessage('All guests added successfully!');
        await _navigateToNextStep();
      } else if (successCount > 0) {
        snackbarController!.showInfoMessage(
          '$successCount of ${companionForms.length} guests added. Failed: ${failed.join(', ')}',
        );
      } else {
        snackbarController!
            .showErrorMessage('Failed to add guests. Please try again.');
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

    final invitationData = await controller!.getLatestInvitationData();
    if (invitationData == null) {
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

    context.go(nextUrl);
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
        '/thank-you?invitationId=${Uri.encodeComponent(controller!.invitationId!)}'
        '&token=${Uri.encodeComponent(controller!.token ?? '')}');
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
    if (widget.readOnly) return _buildReadOnlyPreview(context);

    if (controller == null || snackbarController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Obx(() {
      if (isInitializing.value)
        return const Center(child: CircularProgressIndicator());

      if (companionForms.isEmpty && _companionsTarget > 0) {
        return CompanionsInfoEmptyView(
          readOnly: false,
          savedCount: _savedBase,
          totalCount: _companionsTarget,
          onContinue: _navigateToNextStep,
        );
      }

      return CompanionsInfoContent(
        companionForms: companionForms,
        currentIndex: currentStep.value,
        totalCompanionsCount: _companionsTarget,
        savedCount: _savedBase, // ✅ frozen
        remainingCount: companionForms.length,
        readOnly: false,
        isSubmitting: isSubmitting.value,
        inviteByEmail: false,
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
}
