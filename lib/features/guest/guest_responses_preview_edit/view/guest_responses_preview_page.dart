import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_responses_preview_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/event_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/guest_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/welcome_header.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/demographics_response_view.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/menu_selection_response_view.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';

/// Guest Responses Preview Page
/// Shows the guest's event details, RSVP status, and allows editing responses
class GuestResponsesPreviewPage extends StatelessWidget {
  const GuestResponsesPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GuestResponsesPreviewController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final event = controller.event;
      final guest = controller.guest;

      if (event == null || guest == null) {
        return Center(
          child: AppText.styledBodyMedium(
            context,
            'No event or guest data found',
            color: AppColors.textMuted,
          ),
        );
      }

      return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WelcomeHeader(guestName: guest.name),
                  const SizedBox(height: 32),
                  
                  // 🆕 Companion Selector (show only if there are companions AND main guest can edit)
                  Obx(() {
                    if (!controller.hasCompanions || !controller.canEditCompanionResponses) {
                      return const SizedBox.shrink();
                    }
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                AppText.styledHeadingSmall(
                                  context,
                                  'Select Person',
                                  weight: FontWeight.w600,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Obx(() => Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: controller.selectedGuestId.value,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryAccent),
                                ),
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryAccent),
                                items: controller.allGuests.map((guest) {
                                  final label = guest.isCompanion
                                      ? '${guest.name} (Companion)'
                                      : '${guest.name} (Main Guest)';
                                  return DropdownMenuItem(
                                    value: guest.guestId,
                                    child: AppText.styledBodyMedium(context, label),
                                  );
                                }).toList(),
                                onChanged: (guestId) {
                                  if (guestId != null) {
                                    controller.selectGuest(guestId);
                                  }
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  Obx(() => controller.hasCompanions
                      ? const SizedBox(height: 24)
                      : const SizedBox.shrink()),
                  
                  EventInfoCard(event: event),
                  const SizedBox(height: 24),
                  Obx(() => GuestInfoCard(guest: controller.currentGuest!)),
                  const SizedBox(height: 24),
                  
                  // Demographics Response Card
                  Obx(() {
                    final demographicsResponse = controller.demographicsResponse;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: demographicsResponse != null
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    demographicsResponse != null
                                        ? Icons.question_answer
                                        : Icons.question_answer_outlined,
                                    color: demographicsResponse != null
                                        ? Colors.blue[700]
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText.styledHeadingSmall(
                                        context,
                                        'Demographics',
                                        weight: FontWeight.w600,
                                      ),
                                      const SizedBox(height: 4),
                                      if (demographicsResponse != null)
                                        AppText.styledBodySmall(
                                          context,
                                          '${controller.demographicsAnswerCount} questions answered',
                                          color: AppColors.textMuted,
                                        )
                                      else
                                        AppText.styledBodySmall(
                                          context,
                                          'Not yet submitted',
                                          color: AppColors.textMuted,
                                        ),
                                    ],
                                  ),
                                ),
                                AppSecondaryButton(
                                  text: 'Edit',
                                  icon: Icons.edit,
                                  onPressed: () => controller.editDemographics(context),
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  textColor: AppColors.primaryAccent,
                                  iconColor: AppColors.primaryAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Display actual responses
                            if (demographicsResponse != null)
                              DemographicsResponseView(response: demographicsResponse)
                            else
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppText.styledBodyMedium(
                                        context,
                                        'No demographics submitted yet. Click Edit to get started.',
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Menu Selection Response Card
                  Obx(() {
                    final menuSelectionResponse = controller.menuSelectionResponse;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: menuSelectionResponse != null
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    menuSelectionResponse != null
                                        ? Icons.restaurant_menu
                                        : Icons.restaurant_menu_outlined,
                                    color: menuSelectionResponse != null
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText.styledHeadingSmall(
                                        context,
                                        'Menu Selection',
                                        weight: FontWeight.w600,
                                      ),
                                      const SizedBox(height: 4),
                                      if (menuSelectionResponse != null)
                                        AppText.styledBodySmall(
                                          context,
                                          '${controller.menuItemsSelectedCount} items selected',
                                          color: AppColors.textMuted,
                                        )
                                      else
                                        AppText.styledBodySmall(
                                          context,
                                          'Not yet selected',
                                          color: AppColors.textMuted,
                                        ),
                                    ],
                                  ),
                                ),
                                AppSecondaryButton(
                                  text: 'Edit',
                                  icon: Icons.edit,
                                  onPressed: () => controller.editMenuSelection(context),
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  textColor: AppColors.primaryAccent,
                                  iconColor: AppColors.primaryAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Display actual menu items
                            if (menuSelectionResponse != null)
                              MenuSelectionResponseView(response: menuSelectionResponse)
                            else
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppText.styledBodyMedium(
                                        context,
                                        'No menu items selected yet. Click Edit to choose your meals.',
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      });
  }
}
