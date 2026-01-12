import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Guest Count Page - Allows guests to select number of companions
/// 
/// When [readOnly] is true, displays the page in preview mode without controllers or business logic
class GuestCountPage extends StatefulWidget {
  final String invitationId;
  final String? token;
  final String? eventName; // Optional - will use from GuestLayoutController if available
  final bool readOnly; // If true, displays in preview mode without controllers
  final Event? event; // Required when readOnly is true
  
  const GuestCountPage({
    super.key,
    required this.invitationId,
    this.token,
    this.eventName,
    this.readOnly = false,
    this.event,
  });

  @override
  State<GuestCountPage> createState() => _GuestCountPageState();
}

class _GuestCountPageState extends State<GuestCountPage> {
  RsvpResponseController? controller;
  GuestLayoutController? guestController;
  SnackbarMessageController? snackbarController;
  
  int? selectedCompanionCount;
  bool? isInvitingCompanionsByEmail; // null = not answered, true = send emails, false = answer for them
  bool isSubmitting = false;

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
      
      // Set preview values
      if (widget.event != null) {
        selectedCompanionCount = widget.event!.maxInviteByGuest > 0 ? 1 : 0;
        if (selectedCompanionCount! > 0) {
          isInvitingCompanionsByEmail = false; // Preview: first option selected
        }
      }
      debugPrint('✅ GuestCountPage: Read-only mode, skipping controller initialization');
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
      
      if (Get.isRegistered<SnackbarMessageController>()) {
        snackbarController = Get.find<SnackbarMessageController>();
      }
    } catch (e) {
      // If controllers don't exist, set to null (shouldn't happen in normal flow)
      debugPrint('⚠️ Controllers not found in GuestCountPage: $e');
      controller = null;
      guestController = null;
      snackbarController = null;
    }
    
    // Set initial value if already submitted
    if (controller!.companionsCount != null) {
      selectedCompanionCount = controller!.companionsCount;
      isInvitingCompanionsByEmail = controller!.invitationStatus.value?.isInvitingCompanionsByEmail;
    } else if (controller!.maxGuestInvite == 0) {
      // If no companions allowed, auto-select 0
      selectedCompanionCount = 0;
    }
    
    // Validate user has completed RSVP and is attending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller!.hasResponded || controller!.isAttending != true) {
        // Redirect to RSVP page
        pushAndRemoveAllRoute(
          AppRoute.guestResponse,
          context,
          queryParams: {
            'invitationId': widget.invitationId,
            'token': widget.token ?? '',
          },
        );
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (widget.readOnly || controller == null || snackbarController == null) return;
    
    if (selectedCompanionCount == null) {
      snackbarController!.showErrorMessage('Please select the number of companions');
      return;
    }

    // If companions > 0, require the email invitation choice
    if (selectedCompanionCount! > 0 && isInvitingCompanionsByEmail == null) {
      snackbarController!.showErrorMessage('Please specify how you want to handle companion information');
      return;
    }

    setState(() => isSubmitting = true);

    final success = await controller!.submitCompanions(
      selectedCompanionCount!,
      isInvitingCompanionsByEmail: isInvitingCompanionsByEmail,
    );

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (success) {
      final queryParams = {
        'invitationId': widget.invitationId,
        'token': widget.token ?? '',
      };

      // If user selected companions > 0, always navigate to companions info page
      // Same navigation for both "answer for them" and "send email invites" options
      if (selectedCompanionCount! > 0) {
        pushAndRemoveAllRoute(
          AppRoute.guestCompanionsInfo,
          context,
          queryParams: queryParams,
        );
        return;
      }
      
      // No companions selected, navigate to next step (demographics or menu, but NOT thank you)
      if (controller!.requiresDemographics && !controller!.hasDemographics) {
        pushAndRemoveAllRoute(
          AppRoute.demographics,
          context,
          queryParams: queryParams,
        );
      } else if (!controller!.hasMenuSelection) {
        pushAndRemoveAllRoute(
          AppRoute.menuSelection,
          context,
          queryParams: queryParams,
        );
      } else {
        // If both are completed, still go to demographics or menu (not thank you)
        pushAndRemoveAllRoute(
          controller!.requiresDemographics ? AppRoute.demographics : AppRoute.menuSelection,
          context,
          queryParams: queryParams,
        );
      }
    } else {
      snackbarController!.showErrorMessage(
        controller!.error.value ?? 'Failed to submit. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxGuests = widget.readOnly && widget.event != null
        ? widget.event!.maxInviteByGuest
        : (controller?.maxGuestInvite ?? 0);
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: EdgeInsets.all(AppSpacing.md(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            AppText.styledHeadingMedium(
              context,
              'Guest Information',
              color: AppColors.primaryAccent,
              weight: AppFontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md(context)),
            
            // Description
            AppText.styledBodyLarge(
              context,
              maxGuests > 0
                  ? 'How many companions will you bring to the event?'
                  : 'This invitation is for you only.',
              color: AppColors.textMuted,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl(context)),
            
            if (maxGuests > 0) ...[
              // Dropdown
              AppDropdownMenu<int>(
                label: 'Number of Companions',
                hintText: 'Select number of companions',
                helperText: 'You can bring up to $maxGuests ${maxGuests == 1 ? 'companion' : 'companions'}',
                value: selectedCompanionCount,
                enabled: !widget.readOnly && !isSubmitting,
                width: double.infinity,
                items: List.generate(
                  maxGuests + 1,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      index == 0
                          ? 'No companions (just me)'
                          : index == 1
                              ? '1 companion'
                              : '$index companions',
                    ),
                  ),
                ),
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        setState(() {
                          selectedCompanionCount = value;
                          // Reset email invitation choice when count changes
                          if (value == 0) {
                            isInvitingCompanionsByEmail = null;
                          }
                        });
                      },
              ),
              SizedBox(height: AppSpacing.lg(context)),
              
              // Show email invitation question only if companions > 0
              if (selectedCompanionCount != null && selectedCompanionCount! > 0) ...[
                Container(
                  padding: EdgeInsets.all(AppSpacing.md(context)),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.styledBodyLarge(
                        context,
                        'How would you like to handle companion information?',
                        weight: AppFontWeight.semiBold,
                      ),
                      SizedBox(height: AppSpacing.md(context)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceButton(
                              context,
                              label: 'I\'ll answer for them',
                              description: 'You will fill out all information',
                              isSelected: isInvitingCompanionsByEmail == false,
                              onTap: widget.readOnly
                                  ? null
                                  : () {
                                      setState(() {
                                        isInvitingCompanionsByEmail = false;
                                      });
                                    },
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm(context)),
                          Expanded(
                            child: _buildChoiceButton(
                              context,
                              label: 'Send them email invites',
                              description: 'They will fill out their own information',
                              isSelected: isInvitingCompanionsByEmail == true,
                              onTap: widget.readOnly
                                  ? null
                                  : () {
                                      setState(() {
                                        isInvitingCompanionsByEmail = true;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl(context)),
              ],
            ] else ...[
              // No companions allowed message
              Container(
                padding: EdgeInsets.all(AppSpacing.md(context)),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryAccent,
                      size: 24,
                    ),
                    SizedBox(width: AppSpacing.xxs(context)),
                    Expanded(
                      child: AppText.styledBodyMedium(
                        context,
                        'This is a personal invitation. You cannot bring companions.',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl(context)),
            ],
            
            // Next button
            AppPrimaryButton(
              text: 'Next',
              onPressed: widget.readOnly ? null : _handleSubmit,
              isLoading: isSubmitting,
              width: double.infinity,
              height: 48,
              borderRadius: 12,
            ),
            
            // Error message - only show in non-readonly mode
            if (!widget.readOnly && controller != null)
              Obx(() {
                if (controller!.error.value != null) {
                  return Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md(context)),
                    child: AppText.styledBodySmall(
                      context,
                      controller!.error.value!,
                      color: AppColors.inputError,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(
    BuildContext context, {
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md(context)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.borderInput,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primaryAccent : AppColors.textMuted,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.xxs(context)),
                Expanded(
                  child: AppText.styledBodyMedium(
                    context,
                    label,
                    weight: isSelected ? AppFontWeight.semiBold : AppFontWeight.regular,
                    color: isSelected ? AppColors.primaryAccent : AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xxs(context)),
            Padding(
              padding: EdgeInsets.only(left: 28),
              child: AppText.styledBodySmall(
                context,
                description,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // DON'T delete controller - it's managed by the shell route lifecycle
    super.dispose();
  }
}
