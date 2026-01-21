import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/guest_list_toolbar.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/guest_rsvp_status.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'dart:math' as math;

import 'package:traxx_wepapp/view/admin/venues_and_menus/venues_view.dart';
import 'package:traxx_wepapp/widgets/bottom_scrollbar.dart';

class GuestListSection extends StatelessWidget {
  final String eventName;
  final int? capacity;
  final bool canInvite;
  final int maxInviteByGuest;

  const GuestListSection({
    super.key,
    required this.eventName,
    required this.canInvite,
    this.capacity,
    this.maxInviteByGuest = 0,
  });

  @override
  Widget build(BuildContext context) {
    final AdminGuestListController controller =
        Get.find<AdminGuestListController>();
    final w = MediaQuery.sizeOf(context).width;
    final isNarrow = w < 900;

    return Container(
      padding:
          EdgeInsets.fromLTRB(isNarrow ? 14 : 20, 16, isNarrow ? 14 : 20, 20),
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
          // ✅ Header + toolbar (ONLY)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Guest list',
                style: GoogleFonts.poppins(
                  fontSize: isNarrow ? 14.5 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GuestListToolbar(
                controller: controller,
                eventName: eventName,
                capacity: capacity,
                canInvite: canInvite,
                maxInviteByGuest: maxInviteByGuest,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ Setup hint once
          if (!canInvite)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invites are disabled until you publish the event and complete: Menu & dishes selection and Demographic questions.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!canInvite) const SizedBox(height: 12),

          // ✅ Body
          Obx(() {
            if (!controller.isInitialized.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            const pageSize = 15;
            final allFiltered = controller.filteredGuests;
            final total =
                (allFiltered.length / pageSize).ceil().clamp(1, 999999);

            // ✅ Summary counts (filtered)
            int current = controller.currentPage.value;
            final rsvpMap = controller.rsvpByGuestId;
            int yesCount = 0, noCount = 0, pendingCount = 0;
            final start = current * pageSize;
            final end = math.min(start + pageSize, allFiltered.length);
            final list = allFiltered.sublist(start, end);
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

            for (final g in allFiltered) {
              final id = g.guestId ?? '';
              final rsvp = rsvpMap[id];

              final responded = rsvp != null && rsvp.hasResponded;
              if (!responded) {
                pendingCount++;
                continue;
              }

              if (rsvp.isAttending == true)
                yesCount++;
              else if (rsvp.isAttending == false)
                noCount++;
              else
                pendingCount++;
            }

            if (current >= total) {
              // clamp if filters changed
              current = total - 1;
              controller.currentPage.value = current;
            }
            if (current < 0) {
              current = 0;
              controller.currentPage.value = 0;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary row
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statPill(
                        label: 'No. of Guests will attend',
                        value: yesCount,
                        bg: const Color(0xFFECFDF3),
                        fg: const Color(0xFF027A48),
                        icon: Icons.check_circle_outline,
                      ),
                      _statPill(
                        label: 'No. of Guests will not attend',
                        value: noCount,
                        bg: const Color(0xFFFFF1F2),
                        fg: const Color(0xFFB42318),
                        icon: Icons.cancel_outlined,
                      ),
                      _statPill(
                        label: 'Pending response',
                        value: pendingCount,
                        bg: const Color(0xFFF3F4F6),
                        fg: const Color(0xFF6B7280),
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Table with perfect width + scrollbar when needed
                LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth;

                    // minimum readable width for all columns
                    const minTableWidth = 1100.0;

                    // ✅ perfect behavior:
                    // if available is larger -> table expands to available width
                    // if available is smaller -> keep min width and scrollbar appears
                    final tableWidth =
                        available > minTableWidth ? available : minTableWidth;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: BottomHScrollbar(
                          minWidth: tableWidth,
                          child: DataTable(
                            showCheckboxColumn: false,
                            headingRowHeight: 48,
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 64,

                            headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFF3F4F6)),
                            headingTextStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                            dataTextStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),

                            // ✅ full border + row separators
                            border: const TableBorder(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                              bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              left: BorderSide(color: Color(0xFFE5E7EB)),
                              right: BorderSide(color: Color(0xFFE5E7EB)),
                              horizontalInside:
                                  BorderSide(color: Color(0xFFE5E7EB)),
                              verticalInside: BorderSide.none,
                            ),

                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Max Guest Invite')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Event Presence')),
                              DataColumn(label: Text('Invited')),
                              DataColumn(label: Text('Actions')),
                            ],

                            rows: list.map((guest) {
                              final isDisabledGuest = guest.isDisabled == true;
                              final canInviteThisGuest =
                                  canInvite && !isDisabledGuest;

                              return DataRow(
                                cells: [
                                  DataCell(Text(guest.name)),
                                  DataCell(Text(guest.email)),
                                  DataCell(
                                    DropdownButton<int>(
                                      value: guest.maxGuestInvite,
                                      underline: const SizedBox(),
                                      isDense: true,
                                      focusColor: Colors.transparent,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827),
                                      ),
                                      items: List.generate(
                                        maxInviteByGuest + 1,
                                        (index) => DropdownMenuItem(
                                          value: index,
                                          child: Text(
                                              index == 0 ? 'None' : '$index'),
                                        ),
                                      ),
                                      onChanged: (newValue) async {
                                        if (newValue != null &&
                                            guest.guestId != null) {
                                          final updatedGuest = guest.copyWith(
                                              maxGuestInvite: newValue);
                                          final success = await controller
                                              .updateGuestDirectly(
                                                  updatedGuest);

                                          final snackbarController = Get.find<
                                              SnackbarMessageController>();
                                          if (success) {
                                            snackbarController
                                                .showSuccessMessage(
                                              'Max invite updated to ${newValue == 0 ? 'None' : newValue}',
                                            );
                                          } else {
                                            snackbarController.showErrorMessage(
                                              'Failed to update max invite',
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  DataCell(Text(isDisabledGuest
                                      ? 'Disabled'
                                      : 'Enabled')),
                                  DataCell(_rsvpBadge(
                                    controller
                                        .rsvpByGuestId[guest.guestId ?? ''],
                                  )),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(
                                        guest.isInvited == true
                                            ? Icons.refresh
                                            : Icons.send,
                                        size: 18,
                                        color: canInviteThisGuest
                                            ? (guest.isInvited == true
                                                ? Colors.green
                                                : Colors.blue)
                                            : Colors.grey,
                                      ),
                                      tooltip: isDisabledGuest
                                          ? 'Guest is disabled'
                                          : (!canInvite
                                              ? 'Publish event and select menu + demographic set first'
                                              : (guest.isInvited == true
                                                  ? 'Already invited — click to re-send'
                                                  : 'Invite guest')),
                                      onPressed: canInviteThisGuest
                                          ? () async {
                                              if (guest.guestId == null) return;
                                              final isResend =
                                                  guest.isInvited == true;

                                              final success =
                                                  await controller.inviteGuest(
                                                guest.guestId!,
                                                forceResend: isResend,
                                              );

                                              final snackbarController = Get.find<
                                                  SnackbarMessageController>();
                                              if (success) {
                                                snackbarController
                                                    .showSuccessMessage(
                                                  isResend
                                                      ? 'Invitation re-sent'
                                                      : 'Guest invited',
                                                );
                                              } else {
                                                snackbarController
                                                    .showErrorMessage(
                                                  isResend
                                                      ? 'Failed to re-send invitation'
                                                      : 'Failed to invite guest',
                                                );
                                              }
                                            }
                                          : (!canInvite && !isDisabledGuest)
                                              ? () => Get.find<
                                                          SnackbarMessageController>()
                                                      .showInfoMessage(
                                                    'Before inviting guests, please publish the event and complete: Menu & dishes selection and Demographic questions.',
                                                  )
                                              : null,
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 18),
                                          tooltip: 'Edit',
                                          onPressed: () {
                                            controller.updateAllFields(guest);
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AddGuestPopup(
                                                controller: controller,
                                                isEditMode: true,
                                                maxInviteByGuest:
                                                    maxInviteByGuest,
                                              ),
                                            ).then(
                                                (_) => controller.clearForm());
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18,
                                              color: Colors.redAccent),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title:
                                                    const Text('Delete guest?'),
                                                content: Text(
                                                    'Delete "${guest.name}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (ok == true &&
                                                guest.guestId != null) {
                                              await controller
                                                  .deleteGuest(guest.guestId!);
                                              Get.find<
                                                      SnackbarMessageController>()
                                                  .showSuccessMessage(
                                                      'Guest deleted');
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                if (total > 1)
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: current > 0
                            ? () => controller.currentPage.value = current - 1
                            : null,
                        child: const Text('Previous'),
                      ),
                      Text('Page ${current + 1} of $total'),
                      TextButton(
                        onPressed: current < total - 1
                            ? () => controller.currentPage.value = current + 1
                            : null,
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

  static Widget _rsvpBadge(GuestRsvpStatus? rsvp) {
    if (rsvp == null) {
      return _pill('—', const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
    if (!rsvp.hasResponded) {
      return _pill('Pending', const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
    if (rsvp.isAttending == true) {
      return _pill('Yes', const Color(0xFFECFDF3), const Color(0xFF027A48));
    }
    if (rsvp.isAttending == false) {
      return _pill('No', const Color(0xFFFFF1F2), const Color(0xFFB42318));
    }
    return _pill('Responded', const Color(0xFFF3F4F6), const Color(0xFF6B7280));
  }

  static Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  static Widget _statPill({
    required String label,
    required int value,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
