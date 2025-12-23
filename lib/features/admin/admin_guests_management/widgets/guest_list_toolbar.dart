import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart';
import 'package:traxx_wepapp/utils/guest_template_generator.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

/// Toolbar widget for the guest list section containing search field and action buttons
class GuestListToolbar extends StatelessWidget {
  final AdminGuestListController controller;
  final String eventName;
  final int? capacity;
  final bool canInvite;
  final int maxInviteByGuest;

  const GuestListToolbar({
    super.key,
    required this.controller,
    required this.eventName,
    required this.capacity,
    required this.canInvite,
    required this.maxInviteByGuest,
  });

  void _showSetupHint(BuildContext context) {
    final snackbarController = Get.find<SnackbarMessageController>();
    snackbarController.showInfoMessage(
      'Before inviting guests, please select Menu & dishes and Demographic questions for this event.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        AppSearchInputField(
          hintText: 'Search by name or email',
          controller: controller.searchController,
          onChanged: controller.filterGuests,
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: controller.clearFilter,
          ),
        ),

        const SizedBox(width: 12),

        // Download Guest List button (disabled if no guests)
        Obx(() => AppPrimaryButton(
              onPressed: controller.guests.isEmpty
                  ? null
                  : () => _downloadGuestList(context),
              text: 'Download Guest List',
              icon: Icons.download_outlined,
            )),

        const SizedBox(width: 12),

        // Download Template button
        AppPrimaryButton(
          onPressed: () => _downloadTemplate(context),
          text: 'Download Template',
          icon: Icons.download,
        ),

        const SizedBox(width: 12),

        // Upload CSV/XLSX button
        AppPrimaryButton(
          onPressed: () => _uploadGuestsFile(context),
          text: 'Upload CSV',
          icon: Icons.upload_file,
        ),

        const SizedBox(width: 12),

        // Invite All button
        AppPrimaryButton(
          onPressed: () => _inviteAllGuests(context),
          text: 'Invite All',
          icon: Icons.send,
        ),

        const SizedBox(width: 12),

        // Add Guest button
        AppPrimaryButton(
          onPressed: () => _addGuest(context),
          text: '+ Add Guest',
        ),
      ],
    );
  }

  void _downloadGuestList(BuildContext context) {
    GuestTemplateGenerator.downloadGuestList(
      eventName: eventName.trim().isEmpty ? 'Event' : eventName,
      controller: controller,
    );

    final snackbarController = Get.find<SnackbarMessageController>();
    snackbarController.showSuccessMessage(
      '${controller.guests.length} guests exported successfully',
    );
  }

  void _downloadTemplate(BuildContext context) {
    GuestTemplateGenerator.downloadXlsxTemplate(
      eventName: eventName.trim().isEmpty ? 'Event' : eventName,
      includeExamples: true,
      capacity: capacity,
    );

    final snackbarController = Get.find<SnackbarMessageController>();
    snackbarController.showSuccessMessage(
      capacity != null
          ? 'Excel template with $capacity rows downloaded successfully'
          : 'Excel template downloaded successfully',
    );
  }

  Future<void> _uploadGuestsFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result == null || !context.mounted) return;

    final file = result.files.first;

    try {
      final res = await controller.uploadGuestsFromFile(file);
      final added = res['added'] ?? 0;
      final skipped = res['skipped'] ?? 0;

      if (!context.mounted) return;

      final snackbarController = Get.find<SnackbarMessageController>();

      if (added > 0 && skipped > 0) {
        snackbarController.showInfoMessage(
          'Added $added new guest(s). $skipped guest(s) were already in the system.',
        );
      } else if (added > 0) {
        snackbarController.showSuccessMessage(
          'Successfully uploaded $added guest(s)',
        );
      } else if (skipped > 0) {
        snackbarController.showInfoMessage(
          'All $skipped guest(s) were already in the system.',
        );
      } else {
        snackbarController.showInfoMessage('No guests found in file');
      }
    } catch (e) {
      if (!context.mounted) return;
      final snackbarController = Get.find<SnackbarMessageController>();
      snackbarController.showErrorMessage(e.toString());
    }
  }

  Future<void> _inviteAllGuests(BuildContext context) async {
    if (!canInvite) {
      _showSetupHint(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite All Guests?'),
        content: const Text(
          'This will send invitations to all enabled guests who haven\'t been invited yet. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Invite All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await controller.inviteAllGuests();
      if (!context.mounted) return;

      final snackbarController = Get.find<SnackbarMessageController>();
      if (count > 0) {
        snackbarController.showSuccessMessage('Invited $count guest(s)');
      } else {
        snackbarController.showInfoMessage('No uninvited guests found');
      }
    }
  }

  void _addGuest(BuildContext context) {
    controller.clearForm();
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddGuestPopup(
        controller: controller,
        maxInviteByGuest: maxInviteByGuest,
      ),
    ).then((added) {
      controller.clearForm();
      if (added == true) {
        final snackbarController = Get.find<SnackbarMessageController>();
        snackbarController.showSuccessMessage('Guest added');
      }
    });
  }
}
