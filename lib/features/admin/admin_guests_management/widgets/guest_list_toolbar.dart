import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  GuestListToolbar({
    super.key,
    required this.controller,
    required this.eventName,
    required this.capacity,
    required this.canInvite,
    required this.maxInviteByGuest,
  });

  final RxBool isExpanded = true.obs;

  void toggleExpanded() => isExpanded.value = !isExpanded.value;

  void _showSetupHint(BuildContext context) {
    Get.find<SnackbarMessageController>().showInfoMessage(
      'Before inviting guests, please select Menu & dishes and Demographic questions for this event.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isPhone = w < 600;

    // ✅ actions that NEVER depend on non-reactive values here
    final actions = <_ToolbarAction>[
      _ToolbarAction(
        text: 'Download Guest List',
        icon: Icons.download_outlined,
        onPressed: () => _downloadGuestList(context), // ✅ always enabled
      ),
      _ToolbarAction(
        text: 'Download Template',
        icon: Icons.download,
        onPressed: () => _downloadTemplate(context),
      ),
      _ToolbarAction(
        text: 'Upload CSV',
        icon: Icons.upload_file,
        onPressed: () => _uploadGuestsFile(context),
      ),
      _ToolbarAction(
        text: 'Invite All',
        icon: Icons.send,
        onPressed: () => _inviteAllGuests(context),
      ),
      _ToolbarAction(
        text: '+ Add Guest',
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => _addGuest(context),
      ),
    ];

    // ✅ Desktop/tablet wrap layout
    if (!isPhone) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;

          final searchW = (maxW * 0.35).clamp(260.0, 420.0);
          final remaining = (maxW - searchW - 12).clamp(320.0, 20000.0);

          int cols;
          if (remaining >= 1200) {
            cols = 5;
          } else if (remaining >= 980) {
            cols = 4;
          } else if (remaining >= 760) {
            cols = 3;
          } else if (remaining >= 520) {
            cols = 2;
          } else {
            cols = 1;
          }

          const gap = 10.0;
          final btnW =
              ((remaining - gap * (cols - 1)) / cols).clamp(170.0, 260.0);

          return Wrap(
            spacing: gap,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchW,
                child: AppSearchInputField(
                  hintText: 'Search by name or email',
                  controller: controller.searchController,
                  onChanged: controller.filterGuests,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearFilter,
                  ),
                ),
              ),
              ...actions.map(
                (a) => SizedBox(
                  width: btnW,
                  child: AppPrimaryButton(
                    onPressed: a.onPressed,
                    text: a.text,
                    icon: a.icon,
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // ✅ Phone: search + toggle + grid actions
    const cols = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchInputField(
                hintText: 'Search by name or email',
                controller: controller.searchController,
                onChanged: controller.filterGuests,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clearFilter,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              final expanded = isExpanded.value;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: toggleExpanded,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        expanded ? 'Hide' : 'Actions',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (!isExpanded.value) return const SizedBox.shrink();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.0,
            ),
            itemBuilder: (_, i) {
              final a = actions[i];
              return AppPrimaryButton(
                onPressed: a.onPressed,
                text: a.text,
                icon: a.icon,
                height: 44,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              );
            },
          );
        }),
      ],
    );
  }

  // ✅ Always allowed. If 0 guests, show message instead of disabling.
  void _downloadGuestList(BuildContext context) {
    final totalGuests = controller.guests.length;

    if (totalGuests == 0) {
      Get.find<SnackbarMessageController>()
          .showInfoMessage('No guests to export yet.');
      return;
    }

    GuestTemplateGenerator.downloadGuestList(
      eventName: eventName.trim().isEmpty ? 'Event' : eventName,
      controller: controller,
    );

    Get.find<SnackbarMessageController>().showSuccessMessage(
      '$totalGuests guests exported successfully',
    );
  }

  void _downloadTemplate(BuildContext context) {
    GuestTemplateGenerator.downloadXlsxTemplate(
      eventName: eventName.trim().isEmpty ? 'Event' : eventName,
      includeExamples: true,
      capacity: capacity,
    );

    Get.find<SnackbarMessageController>().showSuccessMessage(
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
      final snackbar = Get.find<SnackbarMessageController>();

      if (added > 0 && skipped > 0) {
        snackbar.showInfoMessage(
          'Added $added new guest(s). $skipped guest(s) were already in the system.',
        );
      } else if (added > 0) {
        snackbar.showSuccessMessage('Successfully uploaded $added guest(s)');
      } else if (skipped > 0) {
        snackbar.showInfoMessage(
            'All $skipped guest(s) were already in the system.');
      } else {
        snackbar.showInfoMessage('No guests found in file');
      }
    } catch (e) {
      if (!context.mounted) return;
      Get.find<SnackbarMessageController>().showErrorMessage(e.toString());
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

      final snackbar = Get.find<SnackbarMessageController>();
      if (count > 0) {
        snackbar.showSuccessMessage('Invited $count guest(s)');
      } else {
        snackbar.showInfoMessage('No uninvited guests found');
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
        Get.find<SnackbarMessageController>().showSuccessMessage('Guest added');
      }
    });
  }
}

class _ToolbarAction {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ToolbarAction({
    required this.text,
    required this.icon,
    required this.onPressed,
  });
}
