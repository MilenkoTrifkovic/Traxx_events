import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/events_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart'
    show AddGuestPopup;
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/utils/guest_template_generator.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

class GuestListSection extends StatelessWidget {
  const GuestListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminGuestListController controller =
        Get.find<AdminGuestListController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + buttons at top-right
          Row(
            children: [
              Expanded(
                child: Text(
                  'Guest list',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSearchInputField(
                hintText: 'Search by name or email',
                controller: controller.searchController,
                onChanged: controller.filterGuests,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clearFilter();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Download Guest List button
              Obx(() => AppPrimaryButton(
                    onPressed: controller.guests.isEmpty
                        ? null
                        : () {
                            // Get event name
                            String eventName = 'Event';
                            try {
                              final eventsController =
                                  Get.find<EventsController>();
                              final event = eventsController
                                  .getEventById(controller.eventId);
                              eventName = event?.name ?? 'Event';
                            } catch (e) {
                              debugPrint(
                                  'Could not find events controller: $e');
                            }

                            GuestTemplateGenerator.downloadGuestList(
                              eventName: eventName,
                              controller: controller,
                            );

                            final snackbarController =
                                Get.find<SnackbarMessageController>();
                            snackbarController.showSuccessMessage(
                                '${controller.guests.length} guests exported successfully');
                          },
                    text: 'Download Guest List',
                    icon: Icons.download_outlined,
                  )),

              const SizedBox(width: 12),

              // Download Excel Template button
              AppPrimaryButton(
                onPressed: () {
                  // Get event details from EventsController using the eventId
                  int? eventCapacity;
                  String eventName = 'Event';
                  try {
                    final eventsController = Get.find<EventsController>();
                    final event =
                        eventsController.getEventById(controller.eventId);
                    eventCapacity = event?.capacity;
                    eventName = event?.name ?? 'Event';
                  } catch (e) {
                    // If controller not found, capacity will be null
                    debugPrint('Could not find events controller: $e');
                  }

                  GuestTemplateGenerator.downloadXlsxTemplate(
                    eventName: eventName,
                    includeExamples: true,
                    capacity: eventCapacity,
                  );

                  final snackbarController =
                      Get.find<SnackbarMessageController>();
                  snackbarController.showSuccessMessage(eventCapacity != null
                      ? 'Excel template with $eventCapacity rows downloaded successfully'
                      : 'Excel template downloaded successfully');
                },
                text: 'Download Template',
                icon: Icons.download,
              ),

              const SizedBox(width: 12),

              // Upload CSV button
              AppPrimaryButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv'],
                  );

                  if (result == null || context.mounted == false) {
                    return; // User canceled
                  }

                  final file = result.files.first;

                  try {
                    final result = await controller.uploadGuestsFromFile(file);
                    final added = result['added'] ?? 0;
                    final skipped = result['skipped'] ?? 0;

                    if (context.mounted) {
                      final snackbarController =
                          Get.find<SnackbarMessageController>();

                      if (added > 0 && skipped > 0) {
                        // Some guests added, some skipped
                        snackbarController.showInfoMessage(
                            'Added $added new guest(s). $skipped guest(s) were already in the system.');
                      } else if (added > 0) {
                        // All guests added successfully
                        snackbarController.showSuccessMessage(
                            'Successfully uploaded $added guest(s)');
                      } else if (skipped > 0) {
                        // All guests were duplicates
                        snackbarController.showInfoMessage(
                            'All $skipped guest(s) were already in the system.');
                      } else {
                        // No guests found in file
                        snackbarController
                            .showInfoMessage('No guests found in file');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final snackbarController =
                          Get.find<SnackbarMessageController>();
                      snackbarController.showErrorMessage(e.toString());
                    }
                  }
                },
                text: 'Upload CSV',
                icon: Icons.upload_file,
              ),

              const SizedBox(width: 12),

              // Invite All button
              AppPrimaryButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Invite All Guests?'),
                      content: const Text(
                          'This will send invitations to all enabled guests who haven\'t been invited yet. Do you want to continue?'),
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
                    final snackbarController =
                        Get.find<SnackbarMessageController>();
                    if (count > 0) {
                      snackbarController
                          .showSuccessMessage('Invited $count guest(s)');
                    } else {
                      snackbarController
                          .showInfoMessage('No uninvited guests found');
                    }
                  }
                },
                text: 'Invite All',
                icon: Icons.send,
              ),

              const SizedBox(width: 12),

              // Add Guest button
              AppPrimaryButton(
                onPressed: () {
                  controller.clearForm();
                  showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AddGuestPopup(controller: controller),
                  ).then((added) {
                    if (added == true) {
                      final snackbarController =
                          Get.find<SnackbarMessageController>();
                      snackbarController.showSuccessMessage('Guest added');
                      controller.clearForm();
                    } else {
                      controller.clearForm();
                    }
                  });
                },
                text: '+ Add Guest',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Body: loading / empty / table - Single Obx watching all observables
          Obx(() {
            if (!controller.isInitialized.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final allFiltered = controller.filteredGuests;
            if (allFiltered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: AppText.styledBodyMedium(
                  context,
                  'No guests yet. Click "Add Guest" to create one.',
                  color: AppColors.textMuted,
                ),
              );
            }

            // Access reactive observables here to register them with Obx
            final list = controller.pagedGuests;
            final current = controller.currentPage.value;
            final total = controller.totalPages;

            // Render paginated DataTable
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.grey.shade50),
                        dividerThickness: 1,
                        columns: const [
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Name'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Email'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('City'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Country'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Gender'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Status'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Invited'))),
                          DataColumn(
                              label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Actions'))),
                        ],
                        rows: list.map((guest) {
                          return DataRow(
                            cells: [
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.name))),
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.email))),
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.city ?? '—'))),
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.country ?? '—'))),
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.gender == null
                                      ? '—'
                                      : (guest.gender == Gender.male
                                          ? 'Male'
                                          : guest.gender == Gender.female
                                              ? 'Female'
                                              : guest.gender ==
                                                      Gender.preferNotToSay
                                                  ? 'Prefer not to say'
                                                  : guest.gender!.name)))),
                              // Status derived from isDisabled flag
                              DataCell(Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(guest.isDisabled == true
                                      ? 'Disabled'
                                      : 'Enabled'))),
                              // Invited column - show button or checkmark aligned left
                              DataCell(
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: guest.isInvited == true
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              size: 18, color: Colors.green),
                                          tooltip: 'Already invited',
                                          onPressed: () {
                                            // Do nothing - guest is already invited
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.send,
                                              size: 18, color: Colors.blue),
                                          tooltip: 'Invite guest',
                                          onPressed: () async {
                                            if (guest.guestId != null) {
                                              final success = await controller
                                                  .inviteGuest(guest.guestId!);
                                              final snackbarController = Get.find<
                                                  SnackbarMessageController>();
                                              if (success) {
                                                snackbarController
                                                    .showSuccessMessage(
                                                        'Guest invited');
                                              } else {
                                                snackbarController
                                                    .showErrorMessage(
                                                        'Failed to invite guest');
                                              }
                                            }
                                          },
                                        ),
                                ),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    tooltip: 'Edit',
                                    onPressed: () {
                                      controller.updateAllFields(guest);
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AddGuestPopup(
                                            controller: controller,
                                            isEditMode: true),
                                      ).then((_) => controller.clearForm());
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.redAccent),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete guest?'),
                                          content:
                                              Text('Delete "${guest.name}"?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx)
                                                        .pop(false),
                                                child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Delete'),
                                            )
                                          ],
                                        ),
                                      );
                                      if (ok == true && guest.guestId != null) {
                                        await controller
                                            .deleteGuest(guest.guestId!);
                                        final snackbarController = Get.find<
                                            SnackbarMessageController>();
                                        snackbarController.showSuccessMessage(
                                            'Guest deleted');
                                      }
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Pagination controls - no Obx needed, variables already accessed above
                if (total > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: current > 0 ? controller.prevPage : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 12),
                      Text('Page ${current + 1} of $total'),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed:
                            current < total - 1 ? controller.nextPage : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
