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
  final RxBool isInitializing = true.obs; // Track form initialization
  final RxInt currentStep = 0.obs; // Track which companion form is being filled

  @override
  void initState() {
    super.initState();
    
    // Skip ALL controller initialization in read-only mode
    // Never call Get.find when readOnly is true
    if (widget.readOnly == true) {
      // Ensure controllers remain null in read-only mode
      controller = null;
      guestController = null;
      snackbarController = null;
      
      // Initialize preview forms
      if (widget.event != null && widget.event!.maxInviteByGuest > 0) {
        // Create preview forms (e.g., 2 forms for preview)
        final previewCount = widget.event!.maxInviteByGuest.clamp(1, 3);
        for (int i = 0; i < previewCount; i++) {
          companionForms.add(CompanionFormData());
          // Set preview data
          companionForms[i].name.text = 'Companion ${i + 1}';
          companionForms[i].email.text = 'companion${i + 1}@example.com';
        }
      }
      
      isInitializing.value = false;
      debugPrint('✅ CompaignonsInfoPage: Read-only mode, skipping controller initialization');
      return;
    }
    
    // Only access controllers in normal (non-readonly) mode
    try {
      // Get invitationId from widget or query params
      final invitationId = widget.invitationId ?? 
          Uri.base.queryParameters['invitationId'] ?? '';
      
      // Check if controllers exist before trying to find them
      if (Get.isRegistered<RsvpResponseController>(tag: invitationId)) {
        controller = Get.find<RsvpResponseController>(tag: invitationId);
      }
      
      if (Get.isRegistered<GuestLayoutController>()) {
        guestController = Get.find<GuestLayoutController>();
      }
      
      if (Get.isRegistered<SnackbarMessageController>()) {
        snackbarController = Get.find<SnackbarMessageController>();
      }

      // Initialize forms asynchronously
      if (controller != null) {
        _initializeForms();
        
        // Validate user has completed RSVP, is attending, and has selected companion count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller!.hasResponded || controller!.isAttending != true) {
            // Redirect to RSVP page
            final queryParams = {
              'invitationId': invitationId,
              if (widget.token != null) 'token': widget.token!,
            };
            pushAndRemoveAllRoute(
              AppRoute.guestResponse,
              context,
              queryParams: queryParams,
            );
          } else if (controller!.companionsCount == null || controller!.companionsCount == 0) {
            // No companions selected, redirect to guest count page
            final queryParams = {
              'invitationId': invitationId,
              if (widget.token != null) 'token': widget.token!,
            };
            pushAndRemoveAllRoute(
              AppRoute.guestCompanions,
              context,
              queryParams: queryParams,
            );
          } else if (controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true) {
            // User chose to send email invites, but they still need to come to this page first
            // TODO: In the future, trigger email sending for companions here
            // For now, allow them to stay on this page (they can see that companions will be invited)
            // The page will show that all companions are already handled via email
          }
        });
      }
    } catch (e) {
      // If controllers don't exist, set to null (shouldn't happen in normal flow)
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
    final isInvitingByEmail = controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;
    
    int remainingCount = companionsCount;
    
    // If inviting by email, check how many companions already exist via groupId
    if (isInvitingByEmail && companionsCount > 0) {
      try {
        // Get existing companion count via controller (which uses service layer)
        final existingCompanionsCount = await controller!.getExistingCompanionCount();
        
        if (existingCompanionsCount != null) {
          remainingCount = (companionsCount - existingCompanionsCount).clamp(0, companionsCount);
          print('✅ Found $existingCompanionsCount existing companions, need $remainingCount more');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking existing companions: $e');
        // Fall back to using remainingCompanionsToCreate
        remainingCount = controller!.remainingCompanionsToCreate;
      }
    } else {
      // For direct creation flow, use existing logic
      remainingCount = controller!.remainingCompanionsToCreate;
    }
    
    // Create a form for each remaining companion
    for (int i = 0; i < remainingCount; i++) {
      companionForms.add(CompanionFormData());
    }
    
    print('✅ Initialized $remainingCount companion forms');
    
    // Mark initialization as complete
    isInitializing.value = false;
    
    // If all companions already exist, navigate to next step
    if (remainingCount == 0 && companionsCount > 0 && controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNextStep();
      });
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
    // Read-only mode: show static preview
    if (widget.readOnly) {
      return _buildReadOnlyPreview(context);
    }
    
    // Normal mode: use reactive controllers
    if (controller == null || snackbarController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Obx(() {
      // Show loading while initializing forms
      if (isInitializing.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final totalCompanionsCount = controller!.companionsCount ?? 0;
      final savedCount = controller!.savedCompanionsCount;
      final remainingCount = companionForms.length; // Use actual form count

      if (remainingCount == 0 && totalCompanionsCount > 0) {
        return CompanionsInfoEmptyView(
          readOnly: widget.readOnly,
          savedCount: savedCount,
          totalCount: totalCompanionsCount,
          onContinue: _navigateToNextStep,
        );
      }

      final currentIndex = currentStep.value;

      return CompanionsInfoContent(
        companionForms: companionForms,
        currentIndex: currentIndex,
        totalCompanionsCount: totalCompanionsCount,
        savedCount: savedCount,
        remainingCount: remainingCount,
        readOnly: widget.readOnly,
        isSubmitting: isSubmitting.value,
        onBack: _handleBack,
        onNext: _handleNext,
        onSubmitAll: _handleSubmitAll,
      );
    });
  }

  /// Build read-only preview version of the page
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
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> _handleNext() async {
    if (widget.readOnly || controller == null || snackbarController == null) {
      return;
    }
    
    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    // Validate current form (UI validation)
    if (!formData.validate()) {
      snackbarController!.showErrorMessage(
        'Please fill in all required fields correctly',
      );
      return;
    }

    // Check if user chose to send email invites
    final isInvitingByEmail = controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    if (isInvitingByEmail) {
      // For email invites, we don't save individual companions here
      // They'll all be sent together when user clicks "Submit All"
      // Just move to next step
      if (currentIndex < companionForms.length - 1) {
        currentStep.value++;
      }
      return;
    }

    // Original flow: Create companion guest directly (isInvitingCompanionsByEmail = false)
    // Get other pending emails for validation
    final otherPendingEmails = <String>[];
    for (int i = 0; i < companionForms.length; i++) {
      if (i != currentIndex && companionForms[i].createdGuestId == null) {
        final email = companionForms[i].email.text.trim();
        if (email.isNotEmpty) {
          otherPendingEmails.add(email);
        }
      }
    }

    // Save current companion before moving to next step (if not already saved)
    if (formData.createdGuestId == null) {
      isSubmitting.value = true;

      // Use controller method that handles validation and snackbar messages
      final guestId = await controller!.validateAndCreateCompanion(
        name: formData.name.text.trim(),
        email: formData.email.text.trim(),
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

      if (guestId == null) {
        return; // Error already shown via snackbar in controller
      }

      formData.createdGuestId = guestId;
      snackbarController!.showSuccessMessage(
        'Companion ${currentIndex + 1} saved successfully!',
      );
    }

    // Move to next step
    if (currentIndex < companionForms.length - 1) {
      currentStep.value++;
    }
  }

  Future<void> _handleSubmitAll() async {
    if (widget.readOnly || controller == null || snackbarController == null) {
      return;
    }
    
    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    // Check if user chose to send email invites
    final isInvitingByEmail = controller!.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    if (isInvitingByEmail) {
      // For email invites: Validate all forms are complete (no need to check createdGuestId)
      for (int i = 0; i < companionForms.length; i++) {
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all companion forms (Companion ${i + 1} is incomplete)',
          );
          currentStep.value = i; // Jump to incomplete form
          return;
        }
      }
    } else {
      // For direct creation: Validate last form (only if not already saved) - UI validation
      if (formData.createdGuestId == null && !formData.validate()) {
        snackbarController!.showErrorMessage(
          'Please fill in all required fields correctly',
        );
        return;
      }

      // Validate all UNSAVED forms are complete - UI validation
      for (int i = 0; i < companionForms.length; i++) {
        // Skip validation for already saved companions
        if (companionForms[i].createdGuestId != null) {
          continue;
        }

        // Only validate forms that haven't been saved yet
        if (!companionForms[i].validate()) {
          snackbarController!.showErrorMessage(
            'Please complete all companion forms (Companion ${i + 1} is incomplete)',
          );
          currentStep.value = i; // Jump to incomplete form
          return;
        }
      }
    }

    // Collect all emails for validation (business logic in controller)
    final emailsToValidate = <String>[];
    for (int i = 0; i < companionForms.length; i++) {
      if (isInvitingByEmail || companionForms[i].createdGuestId == null) {
        emailsToValidate.add(companionForms[i].email.text.trim());
      }
    }

    // Validate all emails are unique (business logic in controller)
    final emailValidation = controller!.validateAllCompanionEmails(emailsToValidate);
    if (emailValidation != null) {
      snackbarController!.showErrorMessage(emailValidation.errorMessage);
      // Jump to the form with the duplicate email
      currentStep.value = emailValidation.duplicateIndex;
      return;
    }

    isSubmitting.value = true;

    try {
      if (isInvitingByEmail) {
        // Flow 1: Send email invitations via Cloud Function
        // Include all form data so guest documents can be created with complete information
        final companionData = companionForms.map((form) => {
          'name': form.name.text.trim(),
          'email': form.email.text.trim(),
          'address': form.address.text.trim().isEmpty ? null : form.address.text.trim(),
          'city': form.city.text.trim().isEmpty ? null : form.city.text.trim(),
          'state': form.selectedState.value,
          'country': form.selectedCountry.value,
          'gender': form.selectedGender.value,
          'maxGuestInvite': 0, // Companions can't invite others
        }).toList();

        final success = await controller!.sendCompanionInvitations(
          companionData: companionData,
        );

        if (success) {
          snackbarController!.showSuccessMessage(
            'All companion invitations sent successfully!',
          );
          // Navigate to next step
          _navigateToNextStep();
        } else {
          // Error already shown via snackbar in controller
        }
      } else {
        // Flow 2: Create companion guests directly (original flow)
        int successCount = 0;
        List<String> failedCompanions = [];

        // Submit each companion using atomic operation
        for (int i = 0; i < companionForms.length; i++) {
          final form = companionForms[i];

          // Skip if already created
          if (form.createdGuestId != null) {
            successCount++;
            continue;
          }

          // Get other pending emails for this form
          final otherPendingEmails = <String>[];
          for (int j = 0; j < companionForms.length; j++) {
            if (j != i && companionForms[j].createdGuestId == null) {
              final email = companionForms[j].email.text.trim();
              if (email.isNotEmpty) {
                otherPendingEmails.add(email);
              }
            }
          }

          // Use controller method that handles validation and snackbar messages
          final guestId = await controller!.validateAndCreateCompanion(
            name: form.name.text.trim(),
            email: form.email.text.trim(),
            address: form.address.text.trim().isEmpty
                ? null
                : form.address.text.trim(),
            city: form.city.text.trim().isEmpty ? null : form.city.text.trim(),
            state: form.selectedState.value,
            country: form.selectedCountry.value,
            gender: form.selectedGender.value,
            otherPendingEmails: otherPendingEmails,
          );

          if (guestId != null) {
            form.createdGuestId = guestId;
            successCount++;
          } else {
            // Error message already shown via snackbar in controller
            failedCompanions.add(form.name.text.trim());
          }
        }

        if (successCount == companionForms.length) {
          snackbarController!.showSuccessMessage(
            'All companions added successfully!',
          );
          // Navigate to next step based on invitation requirements
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
      }
    } catch (e) {
      debugPrint('❌ Error submitting companions: $e');
      snackbarController?.showErrorMessage(
        'An error occurred. Please try again.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }


  /// Navigate to the next step after companions are added
  /// Uses ResponseFlowState to determine the next step (alternating demographics/menu per person)
  Future<void> _navigateToNextStep() async {
    if (widget.readOnly || controller == null) {
      return; // No navigation in read-only mode
    }
    
    try {
      // Fetch the latest invitation document via controller (which uses service layer)
      final invitationData = await controller!.getLatestInvitationData();
      
      if (invitationData == null) {
        debugPrint('⚠️ Invitation not found, using fallback navigation');
        _navigateToFallback();
        return;
      }
      final token = controller!.token ?? '';
      
      // Create flow state from invitation
      final flowState = ResponseFlowState.fromInvitation(
        invitationData,
        token,
        invitationIdOverride: controller!.invitationId!,
      );
      
      // Get next step using the new alternating flow
      final nextStep = flowState.getNextStep();
      final nextUrl = nextStep.buildUrl(controller!.invitationId!, token);
      
      debugPrint('✅ Navigating to next step: ${nextStep.step}, '
          'companionIndex: ${nextStep.companionIndex}, url: $nextUrl');
      
      // Navigate using GoRouter
      context.go(nextUrl);
    } catch (e) {
      debugPrint('❌ Error determining next step: $e');
      // Fallback to old navigation logic
      _navigateToFallback();
    }
  }
  
  /// Fallback navigation if flow state cannot be determined
  void _navigateToFallback() {
    if (widget.readOnly || controller == null) {
      return; // No navigation in read-only mode
    }
    
    // Check demographics (if required)
    if (controller!.requiresDemographics && !controller!.hasDemographics) {
      context.go('/demographics?invitationId=${Uri.encodeComponent(controller!.invitationId!)}&token=${Uri.encodeComponent(controller!.token ?? '')}');
      return;
    }
    
    // Check menu selection
    if (!controller!.hasMenuSelection) {
      context.go('/menu-selection?invitationId=${Uri.encodeComponent(controller!.invitationId!)}&token=${Uri.encodeComponent(controller!.token ?? '')}');
      return;
    }
    
    // All steps completed - go to thank you
    context.go('/thank-you?invitationId=${Uri.encodeComponent(controller!.invitationId!)}');
  }
}
