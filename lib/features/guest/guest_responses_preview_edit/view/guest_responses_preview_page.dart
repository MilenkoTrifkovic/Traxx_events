import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_responses_preview_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/event_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/guest_info_card.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/welcome_header.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/demographics_response_view.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/menu_selection_response_view.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

/// Guest Responses Preview Page
/// Shows the guest's event details, RSVP status, and allows editing responses
class GuestResponsesPreviewPage extends StatelessWidget {
  const GuestResponsesPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GuestResponsesPreviewController());
    final snackbarController = Get.find<SnackbarMessageController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your Event Details'),
        backgroundColor: AppColors.primaryAccent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final success = await controller.logout();
              if (context.mounted) {
                if (success) {
                  snackbarController.showSuccessMessage('Logged out successfully');
                  pushAndRemoveAllRoute(AppRoute.guestLogin, context);
                } else {
                  snackbarController.showErrorMessage('Error logging out. Please try again.');
                }
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final event = controller.event;
        final guest = controller.guest;

        if (event == null || guest == null) {
          return const Center(
            child: Text('No event or guest data found'),
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
                    
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, color: Colors.blue),
                                const SizedBox(width: 12),
                                Text(
                                  'Select Person',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() => DropdownButtonFormField<String>(
                              value: controller.selectedGuestId.value,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: controller.allGuests.map((guest) {
                                final label = guest.isCompanion
                                    ? '${guest.name} (Companion)'
                                    : '${guest.name} (Main Guest)';
                                return DropdownMenuItem(
                                  value: guest.guestId,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (guestId) {
                                if (guestId != null) {
                                  controller.selectGuest(guestId);
                                }
                              },
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
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  demographicsResponse != null
                                      ? Icons.question_answer
                                      : Icons.question_answer_outlined,
                                  color: demographicsResponse != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Demographics',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      if (demographicsResponse != null)
                                        Text(
                                          '${controller.demographicsAnswerCount} questions answered',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => controller.editDemographics(context),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // Display actual responses
                            if (demographicsResponse != null)
                              DemographicsResponseView(response: demographicsResponse)
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No demographics submitted yet',
                                  style: TextStyle(color: Colors.grey),
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
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  menuSelectionResponse != null
                                      ? Icons.restaurant_menu
                                      : Icons.restaurant_menu_outlined,
                                  color: menuSelectionResponse != null
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Menu Selection',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      if (menuSelectionResponse != null)
                                        Text(
                                          '${controller.menuItemsSelectedCount} items selected',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => controller.editMenuSelection(context),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // Display actual menu items
                            if (menuSelectionResponse != null)
                              MenuSelectionResponseView(response: menuSelectionResponse)
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No menu items selected yet',
                                  style: TextStyle(color: Colors.grey),
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
      }),
    );
  }
}
