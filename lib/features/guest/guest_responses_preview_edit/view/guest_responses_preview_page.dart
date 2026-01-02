import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_responses_preview_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

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
          // Logout button
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
                  Text(
                    'Welcome back, ${guest.name}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),

                  // Event Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Event Name', event.name ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Event ID', event.eventId ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Guest Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Name', guest.name ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Email', guest.email ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Batch ID', guest.batchId ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Response Actions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Your Response',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You can view and edit your RSVP, demographics, and menu selections below.',
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: AppPrimaryButton(
                              text: 'Edit RSVP Response',
                              onPressed: controller.editRsvpResponse,
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: AppPrimaryButton(
                              text: 'Edit Demographics',
                              onPressed: controller.editDemographics,
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: AppPrimaryButton(
                              text: 'Edit Menu Selection',
                              onPressed: controller.editMenuSelection,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}