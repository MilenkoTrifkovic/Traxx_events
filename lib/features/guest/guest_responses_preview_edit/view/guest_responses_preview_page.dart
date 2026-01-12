import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_responses_preview_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/event_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/guest_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/welcome_header.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Guest Responses Preview Page
/// Shows the guest's event details and RSVP status
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
                
                // Companion Selector (show only if there are companions AND main guest can edit)
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
              ],
            ),
          ),
        ),
      );
    });
  }
}
