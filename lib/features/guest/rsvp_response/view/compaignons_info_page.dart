import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/widgets/companion_form_widget.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

class CompanionFormData {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController city = TextEditingController();
  final RxnString selectedCountry = RxnString();
  final RxnString selectedState = RxnString();
  final Rxn<Gender> selectedGender = Rxn<Gender>();
  String? createdGuestId; // Store the created guest ID

  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    city.dispose();
  }

  void clear() {
    name.clear();
    email.clear();
    address.clear();
    city.clear();
    selectedCountry.value = null;
    selectedState.value = null;
    selectedGender.value = null;
    createdGuestId = null;
  }

  bool validate() {
    // Try form validation first (works if form is in widget tree)
    final formValid = formKey.currentState?.validate() ?? false;
    if (formValid) return true;
    
    // If form is not in widget tree, manually validate required fields
    // Required fields: name and email
    final nameValid = name.text.trim().isNotEmpty;
    final emailText = email.text.trim();
    final emailValid = emailText.isNotEmpty && 
        ValidationHelper.validateEmail(emailText) == null; // null means valid
    
    return nameValid && emailValid;
  }
}

class CompaignonsInfoPage extends StatefulWidget {
  final String? invitationId;
  final String? token;
  final String? eventName;

  const CompaignonsInfoPage({
    super.key,
    this.invitationId,
    this.token,
    this.eventName,
  });

  @override
  State<CompaignonsInfoPage> createState() => _CompaignonsInfoPageState();
}

class _CompaignonsInfoPageState extends State<CompaignonsInfoPage> {
  late final RsvpResponseController controller;
  late final GuestLayoutController guestController;
  late final SnackbarMessageController snackbarController;

  final List<CompanionFormData> companionForms = [];
  final RxBool isSubmitting = false.obs;
  final RxBool isInitializing = true.obs; // Track form initialization
  final RxInt currentStep = 0.obs; // Track which companion form is being filled

  @override
  void initState() {
    super.initState();
    
    // Get invitationId from widget or query params
    final invitationId = widget.invitationId ?? 
        Uri.base.queryParameters['invitationId'] ?? '';
    
    // Find controller with tag (created by shell route)
    controller = Get.find<RsvpResponseController>(tag: invitationId);
    guestController = Get.find<GuestLayoutController>();
    snackbarController = Get.find<SnackbarMessageController>();

    // Initialize forms asynchronously
    _initializeForms();
    
    // Validate user has completed RSVP, is attending, and has selected companion count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasResponded || controller.isAttending != true) {
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
      } else if (controller.companionsCount == null || controller.companionsCount == 0) {
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
      } else if (controller.invitationStatus.value?.isInvitingCompanionsByEmail == true) {
        // User chose to send email invites, but they still need to come to this page first
        // TODO: In the future, trigger email sending for companions here
        // For now, allow them to stay on this page (they can see that companions will be invited)
        // The page will show that all companions are already handled via email
      }
    });
  }

  Future<void> _initializeForms() async {
    final companionsCount = controller.companionsCount ?? 0;
    final isInvitingByEmail = controller.invitationStatus.value?.isInvitingCompanionsByEmail == true;
    
    int remainingCount = companionsCount;
    
    // If inviting by email, check how many companions already exist via groupId
    if (isInvitingByEmail && companionsCount > 0) {
      try {
        // Get existing companion count via controller (which uses service layer)
        final existingCompanionsCount = await controller.getExistingCompanionCount();
        
        if (existingCompanionsCount != null) {
          remainingCount = (companionsCount - existingCompanionsCount).clamp(0, companionsCount);
          print('✅ Found $existingCompanionsCount existing companions, need $remainingCount more');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking existing companions: $e');
        // Fall back to using remainingCompanionsToCreate
        remainingCount = controller.remainingCompanionsToCreate;
      }
    } else {
      // For direct creation flow, use existing logic
      remainingCount = controller.remainingCompanionsToCreate;
    }
    
    // Create a form for each remaining companion
    for (int i = 0; i < remainingCount; i++) {
      companionForms.add(CompanionFormData());
    }
    
    print('✅ Initialized $remainingCount companion forms');
    
    // Mark initialization as complete
    isInitializing.value = false;
    
    // If all companions already exist, navigate to next step
    if (remainingCount == 0 && companionsCount > 0) {
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
    return Obx(() {
      // Show loading while initializing forms
      if (isInitializing.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final totalCompanionsCount = controller.companionsCount ?? 0;
      final savedCount = controller.savedCompanionsCount;
      final remainingCount = companionForms.length; // Use actual form count

      if (remainingCount == 0 && totalCompanionsCount > 0) {
        return _buildNoCompanionsView(context);
      }

      final currentIndex = currentStep.value;
      final totalSteps = companionForms.length;

      return SingleChildScrollView(
        child: Padding(
          padding: AppPadding.symmetric(
            context,
            horizontalPadding: Sizes.xl,
            verticalPadding: Sizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, totalCompanionsCount, savedCount, remainingCount),
              AppSpacing.verticalLg(context),
              _buildProgressIndicator(context, currentIndex, totalSteps),
              AppSpacing.verticalLg(context),
              _buildCurrentForm(context, currentIndex, savedCount),
              AppSpacing.verticalXl(context),
              _buildNavigationButtons(context, currentIndex, totalSteps),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNoCompanionsView(BuildContext context) {
    final savedCount = controller.savedCompanionsCount;
    final totalCount = controller.companionsCount ?? 0;
    
    return Center(
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            AppSpacing.verticalMd(context),
            AppText.styledHeadingMedium(
              context,
              savedCount > 0 ? 'All Companions Added' : 'No Companions',
              weight: AppFontWeight.semiBold,
            ),
            AppSpacing.verticalSm(context),
            AppText.styledBodyMedium(
              context,
              savedCount > 0
                  ? 'You have already added all $totalCount companion${totalCount > 1 ? 's' : ''} for this event.'
                  : 'You didn\'t select any companions for this event.',
            ),
            AppSpacing.verticalLg(context),
            // Continue button to proceed to next step
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                onPressed: () => _navigateToNextStep(),
                text: 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCompanionsCount, int savedCount, int remainingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledHeadingLarge(
          context,
          'Companion Information',
          weight: AppFontWeight.bold,
        ),
        AppSpacing.verticalSm(context),
        AppText.styledBodyLarge(
          context,
          savedCount > 0
              ? 'You have already added $savedCount companion${savedCount > 1 ? 's' : ''}. '
                'Please provide information for your remaining $remainingCount companion${remainingCount > 1 ? 's' : ''}.'
              : 'Please provide information for your $totalCompanionsCount companion${totalCompanionsCount > 1 ? 's' : ''}.',
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
      BuildContext context, int currentIndex, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledLabelMedium(
          context,
          'Progress: ${currentIndex + 1} of $totalSteps',
          weight: AppFontWeight.medium,
        ),
        AppSpacing.verticalSm(context),
        LinearProgressIndicator(
          value: (currentIndex + 1) / totalSteps,
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildCurrentForm(BuildContext context, int index, int savedCount) {
    if (index >= companionForms.length) return const SizedBox.shrink();

    final formData = companionForms[index];

    return CompanionFormWidget(
      formKey: formData.formKey,
      nameController: formData.name,
      emailController: formData.email,
      addressController: formData.address,
      cityController: formData.city,
      selectedCountry: formData.selectedCountry,
      selectedState: formData.selectedState,
      selectedGender: formData.selectedGender,
      companionNumber: '${savedCount + index + 1}', // Adjust number to account for already saved
    );
  }

  Widget _buildNavigationButtons(
      BuildContext context, int currentIndex, int totalSteps) {
    final isFirstStep = currentIndex == 0;
    final isLastStep = currentIndex == totalSteps - 1;

    return Obx(() {
      final submitting = isSubmitting.value;

      return Row(
        children: [
          // Back button (disabled on first step)
          Expanded(
            child: AppSecondaryButton(
              onPressed: (isFirstStep || submitting) ? null : _handleBack,
              text: 'Back',
            ),
          ),
          AppSpacing.horizontalMd(context),
          // Next/Submit button
          Expanded(
            child: AppPrimaryButton(
              onPressed: submitting
                  ? null
                  : () => isLastStep ? _handleSubmitAll() : _handleNext(),
              text: submitting
                  ? 'Saving...'
                  : isLastStep
                      ? 'Submit All'
                      : 'Next',
            ),
          ),
        ],
      );
    });
  }

  void _handleBack() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> _handleNext() async {
    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    // Validate current form (UI validation)
    if (!formData.validate()) {
      snackbarController.showErrorMessage(
        'Please fill in all required fields correctly',
      );
      return;
    }

    // Check if user chose to send email invites
    final isInvitingByEmail = controller.invitationStatus.value?.isInvitingCompanionsByEmail == true;

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
      final guestId = await controller.validateAndCreateCompanion(
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
      snackbarController.showSuccessMessage(
        'Companion ${currentIndex + 1} saved successfully!',
      );
    }

    // Move to next step
    if (currentIndex < companionForms.length - 1) {
      currentStep.value++;
    }
  }

  Future<void> _handleSubmitAll() async {
    final currentIndex = currentStep.value;
    final formData = companionForms[currentIndex];

    // Check if user chose to send email invites
    final isInvitingByEmail = controller.invitationStatus.value?.isInvitingCompanionsByEmail == true;

    if (isInvitingByEmail) {
      // For email invites: Validate all forms are complete (no need to check createdGuestId)
      for (int i = 0; i < companionForms.length; i++) {
        if (!companionForms[i].validate()) {
          snackbarController.showErrorMessage(
            'Please complete all companion forms (Companion ${i + 1} is incomplete)',
          );
          currentStep.value = i; // Jump to incomplete form
          return;
        }
      }
    } else {
      // For direct creation: Validate last form (only if not already saved) - UI validation
      if (formData.createdGuestId == null && !formData.validate()) {
        snackbarController.showErrorMessage(
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
          snackbarController.showErrorMessage(
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
    final emailValidation = controller.validateAllCompanionEmails(emailsToValidate);
    if (emailValidation != null) {
      snackbarController.showErrorMessage(emailValidation.errorMessage);
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

        final success = await controller.sendCompanionInvitations(
          companionData: companionData,
        );

        if (success) {
          snackbarController.showSuccessMessage(
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
          final guestId = await controller.validateAndCreateCompanion(
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
          snackbarController.showSuccessMessage(
            'All companions added successfully!',
          );
          // Navigate to next step based on invitation requirements
          _navigateToNextStep();
        } else if (successCount > 0) {
          snackbarController.showInfoMessage(
            '$successCount of ${companionForms.length} companions added. '
            'Failed: ${failedCompanions.join(', ')}',
          );
        } else {
          snackbarController.showErrorMessage(
            'Failed to add companions. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error submitting companions: $e');
      snackbarController.showErrorMessage(
        'An error occurred. Please try again.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }


  /// Navigate to the next step after companions are added
  /// Uses ResponseFlowState to determine the next step (alternating demographics/menu per person)
  Future<void> _navigateToNextStep() async {
    try {
      // Fetch the latest invitation document via controller (which uses service layer)
      final invitationData = await controller.getLatestInvitationData();
      
      if (invitationData == null) {
        debugPrint('⚠️ Invitation not found, using fallback navigation');
        _navigateToFallback();
        return;
      }
      final token = controller.token ?? '';
      
      // Create flow state from invitation
      final flowState = ResponseFlowState.fromInvitation(
        invitationData,
        token,
        invitationIdOverride: controller.invitationId!,
      );
      
      // Get next step using the new alternating flow
      final nextStep = flowState.getNextStep();
      final nextUrl = nextStep.buildUrl(controller.invitationId!, token);
      
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
    // Check demographics (if required)
    if (controller.requiresDemographics && !controller.hasDemographics) {
      context.go('/demographics?invitationId=${Uri.encodeComponent(controller.invitationId!)}&token=${Uri.encodeComponent(controller.token ?? '')}');
      return;
    }
    
    // Check menu selection
    if (!controller.hasMenuSelection) {
      context.go('/menu-selection?invitationId=${Uri.encodeComponent(controller.invitationId!)}&token=${Uri.encodeComponent(controller.token ?? '')}');
      return;
    }
    
    // All steps completed - go to thank you
    context.go('/thank-you?invitationId=${Uri.encodeComponent(controller.invitationId!)}');
  }
}
