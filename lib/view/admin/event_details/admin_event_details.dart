import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/view/admin_guest_list.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_photo_manager.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';

// ---------- AdminEventDetails widget (updated) ----------
// class AdminEventDetails extends StatefulWidget {
//   final String eventId;
//   const AdminEventDetails({super.key, required this.eventId});

//   @override
//   State<AdminEventDetails> createState() => _AdminEventDetailsState();
// }

// class _AdminEventDetailsState extends State<AdminEventDetails> {
//   // Now managing 3 panels: Menu, Guest List, Demographic Questions
//   final List<bool> _expandedPanels = [false, false, false];
//   late final AdminEventDetailsController controller;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();

//     // Guest logic (from Milenko)
//     Get.put(AdminGuestListController());

//     controller = AdminEventDetailsController();
//     controller.loadEvent(widget.eventId).then((_) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     controller.dispose();

//     // Clean up guest controller (from Milenko)
//     Get.delete<AdminGuestListController>();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     // Reactive rebuild based on controller.event etc.
//     return Obx(() {
//       final evt = controller.event.value;
//       if (evt == null) {
//         return const Center(
//           child: Text(
//             'Event not found.',
//             style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
//           ),
//         );
//       }

//       final organisation = controller.organisation;
//       final venue = controller.venue;
//       final dateStr =
//           "${evt.date.day.toString().padLeft(2, '0')}.${evt.date.month.toString().padLeft(2, '0')}.${evt.date.year}";
//       final timeStr =
//           "${evt.date.hour.toString().padLeft(2, '0')}:${evt.date.minute.toString().padLeft(2, '0')}";

//       return SingleChildScrollView(
//         child: Column(
//           children: [
//             EventDetailsHeader(
//               title: evt.name,
//               status: evt.status,
//               date: dateStr,
//               time: timeStr,
//               location: organisation?.city ?? '',
//               serviceType: evt.serviceType,
//               venue: venue?.name ?? '',
//             ),
//             ExpansionPanelList(
//               materialGapSize: 12,
//               expandedHeaderPadding: EdgeInsets.zero,
//               dividerColor: Colors.transparent,
//               expansionCallback: (panelIndex, isExpanded) {
//                 setState(() {
//                   _expandedPanels[panelIndex] = !isExpanded;
//                 });
//               },
//               children: [
//                 // 1. Menu Panel
//                 ExpansionPanel(
//                   backgroundColor: AppColors.white,
//                   isExpanded: _expandedPanels[0],
//                   headerBuilder: (context, isExpanded) {
//                     return _buildPanelHeader(context, 'Menu', 0);
//                   },
//                   body: MenuPanelBody(
//                     mainController: controller,
//                   ),
//                 ),

//                 // 2. Guest List Panel (real guest logic integrated)
// ExpansionPanel(
//   backgroundColor: AppColors.white,
//   isExpanded: _expandedPanels[1],
//   headerBuilder: (context, isExpanded) {
//     return GuestPanelHeader(
//       isExpanded: isExpanded,
//       onTap: () {
//         setState(() {
//           _expandedPanels[1] = !_expandedPanels[1];
//         });
//       },
//     );
//   },
//   body: GuestPanelBody(),
// ),

//                 // 3. Demographic Questions Panel
//                 ExpansionPanel(
//                   backgroundColor: AppColors.white,
//                   isExpanded: _expandedPanels[2],
//                   headerBuilder: (context, isExpanded) {
//                     return _buildPanelHeader(
//                       context,
//                       'Demographic Questions',
//                       2,
//                     );
//                   },
//                   body: DemographicQuestionsPanelBody(
//                     controller: controller,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 50),
//           ],
//         ),
//       );
//     });
//   }

//   // Helper widget for panel headers to avoid code duplication
//   Widget _buildPanelHeader(BuildContext context, String title, int index) {
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _expandedPanels[index] = !_expandedPanels[index];
//         });
//       },
//       hoverColor: Colors.transparent,
//       highlightColor: Colors.transparent,
//       splashColor: Colors.transparent,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//         child: Row(
//           children: [
//             AppText.styledHeadingMedium(
//               context,
//               title,
//               color: AppColors.primary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class AdminEventDetails extends StatefulWidget {
  final String eventId;
  const AdminEventDetails({super.key, required this.eventId});

  @override
  State<AdminEventDetails> createState() => _AdminEventDetailsState();
}

class _AdminEventDetailsState extends State<AdminEventDetails> {
  late final AdminEventDetailsController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // create guest controller instance (Milenko's)
    Get.put(AdminGuestListController());

    controller = AdminEventDetailsController();

    // load event then set guest controller's eventId so it can listen
    controller.loadEvent(widget.eventId).then((_) {
      // ensure guest controller listens for this event's guests
      final guestCtrl = Get.find<AdminGuestListController>();
      guestCtrl.setEventId(widget.eventId);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    Get.delete<AdminGuestListController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Obx(() {
      final evt = controller.event.value;
      if (evt == null) {
        return const Center(
          child: Text(
            'Event not found.',
            style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
          ),
        );
      }

      final organisation = controller.organisation;
      final venue = controller.venue;

      final dateStr =
          "${evt.date.day.toString().padLeft(2, '0')}.${evt.date.month.toString().padLeft(2, '0')}.${evt.date.year}";
      final timeStr =
          "${evt.startTime.hour.toString().padLeft(2, '0')}:${evt.startTime.minute.toString().padLeft(2, '0')}";

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EventDetailsHeader(
            //   title: evt.name,
            //   status: evt.status,
            //   date: dateStr,
            //   time: timeStr,
            //   location: organisation?.city ?? '',
            //   serviceType: evt.serviceType,
            //   venue: venue?.name ?? '',
            // ),
            // const SizedBox(height: 24),

            /// Event details section
            EventSummarySection(controller: controller),

            const SizedBox(height: 24),

            /// Row with Menu card + Demographic card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MenuSelectionCard(controller: controller),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: DemographicSelectionCard(controller: controller),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Guest list section (keep Milenko’s logic, but inside a card)
            /// Guest list section class returned to Original Folder from line 1905-2080
            GuestListSection(),
          ],
        ),
      );
    });
  }
}

class DemographicQuestionsPanelBody extends StatelessWidget {
  final AdminEventDetailsController controller;

  const DemographicQuestionsPanelBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final questions = controller.availableQuestionSets;

      // 1. No sets at all → ask user to create
      if (questions.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledBodyMedium(
                context,
                "You haven't created any demographic question sets yet.",
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRoute.hostQuestionSets.path);
                },
                icon: const Icon(Icons.add),
                label: const Text("Create Demographic Questions"),
              )
            ],
          ),
        );
      }

      // 2. There are sets → compute currently selected one (if any)
      final selectedId = controller.selectedDemographicSetId.value;

      QuestionSet? selectedSet;
      if (selectedId != null && selectedId.isNotEmpty) {
        try {
          selectedSet = questions.firstWhere(
            (s) => s.questionSetId == selectedId,
          );
        } catch (_) {
          selectedSet = null;
        }
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------
            // CURRENT SELECTION AREA
            // --------------------------
            if (selectedSet != null) ...[
              Text(
                "Selected Question Set",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(selectedSet.title),
                  subtitle: Text(selectedSet.description ?? ''),
                  trailing: TextButton(
                    child: const Text("Change"),
                    onPressed: () => controller.openDemographicPicker(context),
                  ),
                ),
              ),
            ] else ...[
              Text(
                "No demographic questions selected for this event.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => controller.openDemographicPicker(context),
                child: const Text("Select Demographic Questions"),
              ),
            ],

            const SizedBox(height: 24),

            // --------------------------
            // LIST OF ALL AVAILABLE SETS
            // --------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.styledBodyMedium(
                  context,
                  "Available Question Sets",
                  color: Colors.grey.shade700,
                  weight: FontWeight.w600,
                ),
                TextButton.icon(
                  onPressed: () {
                    context.push(AppRoute.hostQuestionSets.path);
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Manage Sets'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final set = questions[index];
                final selectedId = controller.selectedDemographicSetId.value;
                final isSelected = set.questionSetId == selectedId;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE6F7FF)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Text(set.title,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        set.description.isNotEmpty == true
                            ? set.description
                            : 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                    onTap: () => controller.toggleDemographicSet(
                        context, set.questionSetId),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class DemographicSetPickerDialog extends StatefulWidget {
  final List<QuestionSet> sets;
  final void Function(QuestionSet) onSelected;

  const DemographicSetPickerDialog({
    super.key,
    required this.sets,
    required this.onSelected,
  });

  @override
  State<DemographicSetPickerDialog> createState() =>
      _DemographicSetPickerDialogState();
}

class _DemographicSetPickerDialogState
    extends State<DemographicSetPickerDialog> {
  QuestionSet? selected;

  @override
  Widget build(BuildContext context) {
    // The model now guarantees non-null title/description, but still normalize locally
    final safeSets =
        widget.sets.where((s) => s.questionSetId.trim().isNotEmpty).toList();

    return AlertDialog(
      title: const Text("Select Demographic Question Set"),
      content: SizedBox(
        width: 500,
        child: safeSets.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No question sets available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: safeSets.length,
                itemBuilder: (_, i) {
                  final set = safeSets[i];
                  // Use defensive display strings (should not be null now)
                  final displayTitle = set.title.trim().isEmpty
                      ? '(Untitled set)'
                      : set.title.trim();
                  final displaySubtitle = set.description.trim().isEmpty
                      ? null
                      : set.description.trim();

                  final isSel = selected != null &&
                      selected!.questionSetId == set.questionSetId;

                  return ListTile(
                    title: Text(displayTitle),
                    subtitle:
                        displaySubtitle == null ? null : Text(displaySubtitle),
                    trailing: isSel
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => setState(() => selected = set),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () =>
              Navigator.of(context).pop(null), // return null on cancel
        ),
        ElevatedButton(
          onPressed: selected == null
              ? null
              : () {
                  final sel = selected!;
                  // Defensive check
                  if (sel.questionSetId.trim().isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Selected set is invalid')),
                      );
                    }
                    return;
                  }

                  // Close the dialog and return the selected set to the caller.
                  Navigator.of(context).pop(sel);
                },
          child: const Text("Choose"),
        )
      ],
    );
  }
}

class EventSummarySection extends StatelessWidget {
  final AdminEventDetailsController controller;

  const EventSummarySection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final evt = controller.event.value;
      if (evt == null) return const SizedBox.shrink();
      final organisation = controller.organisation;
      final venue = controller.venue;

      final dateStr =
          "${evt.date.day.toString().padLeft(2, '0')}.${evt.date.month.toString().padLeft(2, '0')}.${evt.date.year}";
      final timeStr =
          "${evt.date.hour.toString().padLeft(2, '0')}:${evt.date.minute.toString().padLeft(2, '0')}";

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// title + edit icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  evt.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit event details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => EditEventDetailsDialog(
                        controller: controller,
                        initialEvent: evt,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _pill(
                  icon: Icons.event,
                  label: '$dateStr • $timeStr',
                ),
                _pill(
                  icon: Icons.place,
                  label: organisation?.city ?? 'Location not set',
                ),
                _pill(
                  icon: Icons.location_city,
                  label: venue?.name.capitalize ?? 'Venue not set',
                ),
                _pill(
                  icon: Icons.restaurant,
                  label: evt.serviceType.name.isEmpty
                      ? 'Service type'
                      : evt.serviceType.name[0].toUpperCase() +
                          evt.serviceType.name.substring(1),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class EditEventDetailsDialog extends StatefulWidget {
  final AdminEventDetailsController controller;
  final Event initialEvent;

  const EditEventDetailsDialog({
    super.key,
    required this.controller,
    required this.initialEvent,
  });

  @override
  State<EditEventDetailsDialog> createState() => _EditEventDetailsDialogState();
}

class _EditEventDetailsDialogState extends State<EditEventDetailsDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late String _serviceType;
  bool _saving = false;

  // Venue selection - tracked by child widget
  String? _selectedVenueId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialEvent.name);
    // Use address (String) — don't use LatLng directly
    _locationCtrl =
        TextEditingController(text: widget.initialEvent.address ?? '');
    // ServiceType is enum; use its name to bind to Dropdown
    _serviceType = widget.initialEvent.serviceType.name;
    // Initialize selected venue
    _selectedVenueId = widget.initialEvent.venueId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit event details'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location (address)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                decoration: const InputDecoration(
                  labelText: 'Service type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'buffet',
                    child: Text('Buffet'),
                  ),
                  DropdownMenuItem(
                    value: 'plated',
                    child: Text('Plated'),
                  ),
                ],
                onChanged: (v) => setState(() => _serviceType = v ?? 'buffet'),
              ),
              const SizedBox(height: 12),
              // Venue Selection and Photo Management
              // Note: Photo add/remove happens immediately, independent of save button
              VenuePhotoManager(
                initialVenueId: _selectedVenueId,
                onVenueSelected: (venueId) {
                  setState(() {
                    _selectedVenueId = venueId;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    // small inline validation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Event name cannot be empty')),
                    );
                    return;
                  }

                  setState(() => _saving = true);
                  try {
                    // Update event core details
                    await widget.controller.updateEventCoreDetails(
                      name: name,
                      serviceType: _serviceType,
                      address: _locationCtrl.text.trim().isEmpty
                          ? null
                          : _locationCtrl.text.trim(),
                    );

                    // Update venue if it changed
                    // Note: Photos are managed independently and immediately by VenuePhotoManager
                    if (_selectedVenueId != null &&
                        _selectedVenueId != widget.initialEvent.venueId) {
                      // Just update the event's venueId, no photo changes
                      await widget.controller.updateEventVenueAndPhotos(
                        venueId: _selectedVenueId!,
                      );
                    }

                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save changes: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class MenuSelectionCard extends StatelessWidget {
  final AdminEventDetailsController controller;

  const MenuSelectionCard({super.key, required this.controller});

  Future<void> _openMenuDialog(BuildContext context) async {
    final currentMenuId = controller.selectedMenu.value?.id;
    final currentItemIds = controller.selectedMenuItemIds.toList();

    await showDialog(
      context: context,
      builder: (_) => MenuAndItemsDialog(
        controller: controller,
        initialMenuId: currentMenuId,
        initialItemIds: currentItemIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedMenu = controller.selectedMenu.value;
      final selectedItemIds = controller.selectedMenuItemIds.toList();
      final allItems = controller.menuItems.toList();
      final NumberFormat currency =
          NumberFormat.currency(locale: 'en_IN', symbol: '₹');

      // compute selected items & total
      final selectedItems = allItems
          .where((i) => selectedItemIds.contains(i.menuItemId))
          .toList(growable: false);

      final double total = selectedItems.map((i) {
        final p = i.price;
        if (p == null) return 0.0;
        return p.toDouble();
        return double.tryParse(p.toString()) ?? 0.0;
      }).fold(0.0, (a, b) => a + b);

      return Container(
        padding: const EdgeInsets.all(20),
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
            /// Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu & dishes',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  tooltip:
                      selectedMenu == null ? 'Select menu' : 'Edit selection',
                  icon: Icon(
                    selectedMenu == null ? Icons.add : Icons.edit_outlined,
                  ),
                  onPressed: () => _openMenuDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (selectedMenu == null) ...[
              Text(
                'Please select the menu and menu items.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openMenuDialog(context),
                child: const Text('Choose menu'),
              ),
            ] else ...[
              Text(
                selectedMenu.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selectedMenu.description != null &&
                  selectedMenu.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  selectedMenu.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (selectedItems.isEmpty)
                Text(
                  'No dishes selected for this event.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...selectedItems.map((item) => _SelectedDishRow(item)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          currency.format(total),
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  ],
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _SelectedDishRow(MenuItem item) {
    // helpers similar to dialog — safe handling of enums or strings
    String foodTypeLabel() {
      final dynamic ft = item.foodType;
      if (ft == null) return '';
      var raw = ft;
      if (raw is! String) raw = raw.toString();
      raw = raw.split('.').last.replaceAll('_', '').trim().toLowerCase();
      if (raw.contains('non') || raw.contains('nonveg')) return 'Non-Veg';
      if (raw.contains('veg')) return 'Veg';
      if (raw.isEmpty) return '';
      return raw[0].toUpperCase() + raw.substring(1);
    }

    String categoryLabel() {
      final dynamic c = item.category;
      if (c == null) return '';
      var raw = c;
      if (raw is! String) raw = raw.toString();
      raw = raw.split('.').last.replaceAll('_', ' ').trim();
      if (raw.isEmpty) return '';
      return raw
          .split(' ')
          .map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1)))
          .join(' ');
    }

    bool isVeg0() {
      final f = foodTypeLabel();
      if (f.isNotEmpty) {
        return f.toLowerCase().contains('veg') &&
            !f.toLowerCase().startsWith('non');
      }
      final cat = categoryLabel();
      return cat.toLowerCase().contains('veg');
    }

    final bool isVeg = isVeg0();
    final String ftLabel = foodTypeLabel();
    final String catLabel = categoryLabel();
    final NumberFormat currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final price = item.price;
    final double p = (price == null) ? 0.0 : price.toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // square veg/non-veg icon
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isVeg ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (ftLabel.isNotEmpty)
                      Text(
                        ftLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    if (ftLabel.isNotEmpty && catLabel.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•',
                            style: TextStyle(color: Color(0xFFCBD5E1))),
                      ),
                    if (catLabel.isNotEmpty)
                      Text(
                        catLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
          Text(
            currency.format(p),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class MenuAndItemsDialog extends StatefulWidget {
  final AdminEventDetailsController controller;
  final String? initialMenuId;
  final List<String> initialItemIds;

  const MenuAndItemsDialog({
    super.key,
    required this.controller,
    this.initialMenuId,
    required this.initialItemIds,
  });

  @override
  State<MenuAndItemsDialog> createState() => _MenuAndItemsDialogState();
}

class _MenuAndItemsDialogState extends State<MenuAndItemsDialog> {
  String? _menuId;
  MenuModel? _menu;
  List<MenuItem> _items = [];
  final Set<String> _selectedItemIds = {};
  bool _loadingItems = false;
  bool _saving = false;

  final NumberFormat _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _menuId = widget.initialMenuId ??
        (widget.controller.availableMenus.isNotEmpty
            ? widget.controller.availableMenus.first.id
            : null);
    _selectedItemIds.addAll(widget.initialItemIds);
    if (_menuId != null) {
      _menu = widget.controller.availableMenus
          .firstWhereOrNull((m) => m.id == _menuId);
      _loadItems(_menuId!);
    }
  }

  Future<void> _loadItems(String menuId) async {
    setState(() {
      _loadingItems = true;
      _items = [];
    });
    try {
      final list = await widget.controller.fetchMenuItemsForMenu(menuId);
      setState(() {
        _items = list;
      });
    } catch (e, st) {
      debugPrint('Failed to load menu items: $e\n$st');
      setState(() {
        _items = [];
      });
    } finally {
      setState(() {
        _loadingItems = false;
      });
    }
  }

  double _priceOf(MenuItem item) {
    try {
      final p = item.price;
      if (p == null) return 0.0;
      return p.toDouble();
      return double.tryParse(p.toString()) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Returns 'Veg' or 'Non-Veg' (or a cleaned fallback) without the enum prefix.
  /// Returns a short, user-friendly food type label like "Veg" or "Non-Veg".
  /// Handles cases where item.foodType is an enum (FoodType) or a String.
  /// Return "Veg" / "Non-Veg" or a readable fallback for item.foodType.
  /// Accepts String or enum values like FoodType.veg
  String _foodTypeLabel(MenuItem item) {
    final ft = item.foodType; // FoodType?
    if (ft == null) return '';

    // Convert enum to string (e.g. "FoodType.veg" -> "veg")
    String raw = ft.toString().split('.').last.trim().toLowerCase();

    // Standardize outputs
    if (raw == 'veg') return 'Veg';
    if (raw == 'nonVeg' || raw == 'non_veg' || raw == 'nonveg') {
      return 'Non-Veg';
    }

    // Fallback
    return raw.isNotEmpty ? raw[0].toUpperCase() + raw.substring(1) : '';
  }

  /// Return human-friendly title-cased category label.
  /// Handles MenuCategory enum or String.
  // String _categoryLabel(MenuItem item) {
  //   final c = item.category;
  //   if (c == null) return '';

  String _categoryLabel(MenuItem item) {
    final c = item.category;

    // Convert enum to readable string
    String raw = c.toString().split('.').last.replaceAll('_', ' ').trim();

    if (raw.isEmpty) return '';

    return raw
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // raw = raw.replaceAll('_', ' ').trim();

  // if (raw.isEmpty) return '';
  // return _titleCase(raw);
  // }

  /// Simple helper to convert "main_course" / "mainCourse" / "main course"
  /// into "Main Course".
  String _titleCase(String input) {
    // try to insert spaces for camelCase tokens like "mainCourse"
    final inserted = input.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );

    final parts = inserted
        .replaceAll('_', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    return parts
        .map((w) =>
            w[0].toUpperCase() +
            (w.length > 1 ? w.substring(1).toLowerCase() : ''))
        .join(' ');
  }

  /// Small square icon (bordered) with inner fill — looks more like real veg/non-veg marker.
  Widget _foodSquareIcon(bool isVeg) {
    final color = isVeg ? Colors.green : Colors.red;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }

  double get _selectedTotal {
    return _items
        .where((i) => _selectedItemIds.contains(i.menuItemId))
        .map(_priceOf)
        .fold(0.0, (a, b) => a + b);
  }

  void _toggleSelection(MenuItem item) {
    setState(() {
      if (_selectedItemIds.contains(item.menuItemId)) {
        _selectedItemIds.remove(item.menuItemId);
      } else {
        _selectedItemIds.add(item.menuItemId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menus = widget.controller.availableMenus;

    return AlertDialog(
      title: Text(
        'Select menu & dishes',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 880, // slightly bigger for better view
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Menu',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _menuId,
                  isExpanded: true,
                  items: menus
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              // optional small meta on right
                              if (m.description != null &&
                                  m.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    m.description!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _menuId = value;
                      _menu = menus.firstWhereOrNull((m) => m.id == value);
                      _items = [];
                      _selectedItemIds.clear();
                    });
                    _loadItems(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_menu != null &&
                _menu!.description != null &&
                _menu!.description!.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _menu!.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list (left)
                Expanded(
                  flex: 3,
                  child: _buildItemsList(),
                ),

                const SizedBox(width: 18),

                // Selected list (right)
                Expanded(
                  flex: 2,
                  child: _buildSelectedList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving || _menuId == null
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.controller.applyMenuSelection(
                    _menuId!,
                    _selectedItemIds.toList(),
                  );
                  if (mounted) Navigator.of(context).pop();
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Confirm'),
                    const SizedBox(width: 12),
                    Text(
                      _currency.format(_selectedTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    if (_menuId == null) {
      return const Text('Select a menu to see its dishes.');
    }
    if (_loadingItems) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_items.isEmpty) {
      return const Text('This menu has no items.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu items',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, idx) {
              final item = _items[idx];
              final isSelected = _selectedItemIds.contains(item.menuItemId);
              final bool isVeg = (item.category is MenuCategory)
                  ? item.category.isVeg
                  : (item.category is String
                      ? (item.category as String).toLowerCase().contains('veg')
                      : (item.foodType != null &&
                          item.foodType
                              .toString()
                              .toLowerCase()
                              .contains('veg')));

              final double price = _priceOf(item);
              final String priceLabel = _currency.format(price);
              final String foodTypeLabel =
                  _foodTypeLabel(item); // 'Veg' / 'Non-Veg'
              final String categoryLabel = _categoryLabel(item);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.green.shade700
                        : Colors.grey.shade300,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    _foodSquareIcon(isVeg),
                    const SizedBox(width: 12),

                    // Name + small meta (food type + category)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // show "Veg • Category" or "Non-Veg • Category"
                          Text(
                            [
                              if (foodTypeLabel.isNotEmpty) foodTypeLabel,
                              if (categoryLabel.isNotEmpty) categoryLabel
                            ].join(' • '),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        priceLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Add / Remove
                    TextButton(
                      onPressed: () => _toggleSelection(item),
                      child: Text(isSelected ? 'Remove' : 'Add'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedList() {
    final selectedItems = _items
        .where((i) => _selectedItemIds.contains(i.menuItemId))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected items',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedItems.isEmpty)
          Text(
            'No items selected yet.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          )
        else
          SizedBox(
            height: 380,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedItems.length,
                    itemBuilder: (_, idx) {
                      final item = selectedItems[idx];
                      final double price = _priceOf(item);
                      final String priceLabel = _currency.format(price);
                      final String foodTypeLabel = _foodTypeLabel(item);
                      final String categoryLabel = _categoryLabel(item);
                      final bool isVeg = foodTypeLabel.toLowerCase() == 'veg';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            _foodSquareIcon(isVeg),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (foodTypeLabel.isNotEmpty)
                                        foodTypeLabel,
                                      if (categoryLabel.isNotEmpty)
                                        categoryLabel
                                    ].join(' • '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              priceLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedItemIds.remove(item.menuItemId);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _currency.format(_selectedTotal),
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DemographicSelectionCard extends StatelessWidget {
  final AdminEventDetailsController controller;

  const DemographicSelectionCard({super.key, required this.controller});

  void _openDialog(BuildContext context) async {
    // Defensive: ensure the event has been loaded before allowing selection
    if (controller.eventDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Event not loaded yet. Try again shortly.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to manage sets.')),
      );
      return;
    }

    // Keep sets that have a valid id; titles are safe in the model
    final cleanedSets = controller.availableQuestionSets
        .where((s) => s.questionSetId.trim().isNotEmpty)
        .toList();

    if (cleanedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid demographic sets available.')),
      );
      return;
    }

    // Show dialog and await result (QuestionSet or null)
    final QuestionSet? picked = await showDialog<QuestionSet?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DemographicSetPickerDialog(
        sets: cleanedSets,
        onSelected: (selected) async {
          try {
            await controller.chooseDemographicSet(selected.questionSetId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // safe navigation
              context.push('/somewhere');
            });
          } catch (e, st) {
            debugPrint('Error selecting demographic set: $e\n$st');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to apply selection.')),
              );
            }
          }
          // Optionally close the dialog here if you want the caller to close it:
          Navigator.of(context).pop();
        },
      ),
    );

    // If user cancelled or dismissed, do nothing
    if (picked == null) return;

    // Persist selection and handle errors here, AFTER the dialog is closed.
    try {
      await controller.chooseDemographicSet(picked.questionSetId);
      // If you need to navigate somewhere after successful selection,
      // do it here using `context` (caller context), e.g.:
      // if (mounted) context.push('/some-target');  <-- only if you actually need to navigate
    } catch (e, st) {
      debugPrint('Error selecting demographic set: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply selection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final questions = controller.availableQuestionSets;
      final selectedId = controller.selectedDemographicSetId.value;

      // find selected set (safe)
      QuestionSet? selectedSet;
      if ((selectedId ?? '').trim().isNotEmpty) {
        try {
          selectedSet =
              questions.firstWhere((s) => s.questionSetId == selectedId);
        } catch (_) {
          selectedSet = null;
        }
      }

      return Container(
        padding: const EdgeInsets.all(20),
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
            /// header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Demographic questions',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: selectedSet == null
                      ? 'Select question set'
                      : 'Change selection',
                  icon: Icon(
                      selectedSet == null ? Icons.add : Icons.edit_outlined),
                  onPressed: () {
                    if (questions.isEmpty) {
                      context.push(AppRoute.hostQuestionSets.path);
                      return;
                    }
                    _openDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (questions.isEmpty) ...[
              Text(
                "You haven't created any demographic question sets yet.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(AppRoute.hostQuestionSets.path),
                child: const Text('Create demographic questions'),
              ),
            ] else if (selectedSet == null) ...[
              Text(
                'Please select a question set for this event.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _openDialog(context),
                child: const Text('Choose set'),
              ),
            ] else ...[
              Text(
                selectedSet.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selectedSet.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  selectedSet.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    });
  }
}
