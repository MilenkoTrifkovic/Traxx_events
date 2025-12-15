import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart'
    show AddGuestPopup;
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';

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
    Get.put(AdminGuestListController());
    controller = AdminEventDetailsController();
    controller.loadEvent(widget.eventId).then((_) {
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
            EventDetailsHeader(
              title: evt.name,
              status: evt.status,
              date: dateStr,
              time: timeStr,
              location: organisation?.city ?? '',
              serviceType: evt.serviceType,
              venue: venue?.name ?? '',
            ),
            const SizedBox(height: 24),

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
                  label: venue?.name ?? 'Venue not set',
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialEvent.name);
    // Use address (String) — don't use LatLng directly
    _locationCtrl =
        TextEditingController(text: widget.initialEvent.address ?? '');
    // ServiceType is enum; use its name to bind to Dropdown
    _serviceType = widget.initialEvent.serviceType.name;
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
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
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
                    await widget.controller.updateEventCoreDetails(
                      name: name,
                      serviceType: _serviceType,
                      address: _locationCtrl.text.trim().isEmpty
                          ? null
                          : _locationCtrl.text.trim(),
                    );
                    if (mounted) Navigator.of(context).pop();
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

      // category + foodType counts
      final Map<String, int> typeCounts = {};
      final Map<String, int> catCounts = {};
      for (final i in selectedItems) {
        final ft = _foodTypeLabel(i);
        final cat = _categoryLabel(i).isEmpty ? 'Other' : _categoryLabel(i);
        typeCounts[ft] = (typeCounts[ft] ?? 0) + 1;
        catCounts[cat] = (catCounts[cat] ?? 0) + 1;
      }

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menu & dishes',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                IconButton(
                  tooltip:
                      selectedMenu == null ? 'Select menu' : 'Edit selection',
                  icon: Icon(
                      selectedMenu == null ? Icons.add : Icons.edit_outlined),
                  onPressed: () => _openMenuDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (selectedMenu == null) ...[
              Text('Please select the menu and menu items.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _openMenuDialog(context),
                child: Text('Choose menu', style: GoogleFonts.poppins()),
              ),
            ] else ...[
              // show only menu name and description
              Text(selectedMenu.name,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (selectedMenu.description != null &&
                  selectedMenu.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(selectedMenu.description!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF6B7280))),
              ],
              const SizedBox(height: 12),
              if (selectedItems.isEmpty)
                Text('No dishes selected for this event.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF6B7280)))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top summary chips (veg/non-veg/category counts)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _summaryChip('Total', selectedItems.length),
                        ...typeCounts.entries
                            .map((e) => _summaryChip(e.key, e.value)),
                        ...catCounts.entries
                            .map((e) => _summaryChip(e.key, e.value)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // selected items list (limit visual height; scroll if many)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: Scrollbar(
                        child: ListView.separated(
                          itemCount: selectedItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, idx) =>
                              selectedDishRow(selectedItems[idx]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(currency.format(total),
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _summaryChip(String label, int count) {
    final bool isVeg = label.toLowerCase().contains('veg') &&
        !label.toLowerCase().startsWith('non');
    final bool isNonVeg = label.toLowerCase().contains('non') ||
        label.toLowerCase().contains('non-veg');
    final bg = isVeg
        ? Colors.green.shade50
        : (isNonVeg ? Colors.red.shade50 : Colors.grey.shade50);
    final border = isVeg
        ? Colors.green.shade200
        : (isNonVeg ? Colors.red.shade200 : Colors.grey.shade200);
    final textColor = isVeg
        ? Colors.green.shade800
        : (isNonVeg ? Colors.red.shade800 : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border)),
      child: Text('$label • $count',
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget selectedDishRow(MenuItem item) {
    final String ftLabel = _foodTypeLabel(item);
    final String catLabel = _categoryLabel(item);
    final bool isVeg = ftLabel.toLowerCase() == 'veg' ||
        _isVegByCategory(item); // fallback to category
    final NumberFormat currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final price = item.price;
    final double p = (price == null)
        ? 0.0
        : (price is num
            ? price.toDouble()
            : double.tryParse(price.toString()) ?? 0.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFCBD5E1))),
            child: Center(
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: isVeg ? Colors.green : Colors.red,
                        shape: BoxShape.circle))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                if (ftLabel.isNotEmpty)
                  Text(ftLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                if (ftLabel.isNotEmpty && catLabel.isNotEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('•',
                          style: TextStyle(color: Color(0xFFCBD5E1)))),
                if (catLabel.isNotEmpty)
                  Text(catLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF6B7280))),
              ])
            ]),
          ),
          Text(currency.format(p),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------- Robust helpers (no unnecessary casts) ----------

  /// Return 'Veg' / 'Non-Veg' or '' if unknown
  String _foodTypeLabel(MenuItem item) {
    final dynamic ft = item.foodType;
    if (ft == null) return '';

    String raw;
    if (ft is FoodType) {
      raw = ft.name; // safe: `ft` narrowed to FoodType
    } else if (ft is String) {
      raw = ft;
    } else {
      raw = ft.toString();
    }

    // normalize: take last segment if something like 'FoodType.veg'
    final String last =
        raw.split('.').last.replaceAll('_', '').trim().toLowerCase();

    if (last.contains('non')) return 'Non-Veg';
    if (last.contains('veg')) return 'Veg';
    if (last.isEmpty) return '';
    return last[0].toUpperCase() + last.substring(1);
  }

  /// Return category label (title-cased) or ''
  String _categoryLabel(MenuItem item) {
    final dynamic c = item.category;
    if (c == null) return '';

    String raw;
    if (c is MenuCategory) {
      raw = c.name; // safe: `c` narrowed to MenuCategory
    } else if (c is String) {
      raw = c;
    } else {
      raw = c.toString();
    }

    final String last = raw.split('.').last.replaceAll('_', ' ').trim();
    if (last.isEmpty) return '';
    return _titleCase(last);
  }

  /// Determine veg using MenuCategory.isVeg if possible, else fall back to foodType label
  bool _isVegByCategory(MenuItem item) {
    final dynamic c = item.category;
    if (c is MenuCategory) return c.isVeg;
    final ft = _foodTypeLabel(item).toLowerCase();
    return ft == 'veg';
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
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

  // new controllers for scrolling
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  // local filters (kept in state)
  String search = '';
  String? selectedCategoryFilter;
  String? selectedFoodTypeFilter;

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

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems(String menuId) async {
    setState(() {
      _loadingItems = true;
      _items = [];
    });
    try {
      final list = await widget.controller.fetchMenuItemsForMenu(menuId);
      setState(() => _items = list);
    } catch (e, st) {
      debugPrint('Failed to load menu items: $e\n$st');
      setState(() => _items = []);
    } finally {
      setState(() => _loadingItems = false);
    }
  }

  double _priceOf(MenuItem item) {
    final p = item.price;
    if (p == null) return 0.0;
    if (p is num) return p.toDouble();
    return double.tryParse(p.toString()) ?? 0.0;
  }

  void _toggleSelection(MenuItem item) {
    setState(() {
      if (_selectedItemIds.contains(item.menuItemId)) {
        _selectedItemIds.remove(item.menuItemId);
      } else {
        _selectedItemIds.add(item.menuItemId!);
      }
    });

    // auto scroll right to top to reveal new selection
    if (_rightScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _rightScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      });
    }
  }

  double get _selectedTotal => _items
      .where((i) => _selectedItemIds.contains(i.menuItemId))
      .map(_priceOf)
      .fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final menus = widget.controller.availableMenus;

    // derive lists & counts from _items
    final allCategories = _items
        .map((it) => _categoryLabelFor(it))
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final Map<String, int> leftCategoryCounts = {};
    final Map<String, int> leftFoodTypeCounts = {};
    for (final it in _items) {
      final cat =
          _categoryLabelFor(it).isEmpty ? 'Other' : _categoryLabelFor(it);
      leftCategoryCounts[cat] = (leftCategoryCounts[cat] ?? 0) + 1;
      final ft =
          _foodTypeLabelFor(it).isEmpty ? 'Other' : _foodTypeLabelFor(it);
      leftFoodTypeCounts[ft] = (leftFoodTypeCounts[ft] ?? 0) + 1;
    }

    // filtered items
    final filtered = _items.where((it) {
      final nameOk =
          it.name.toLowerCase().contains(search.toLowerCase().trim());
      final cat = _categoryLabelFor(it);
      final catOk = selectedCategoryFilter == null ||
          selectedCategoryFilter == 'All' ||
          selectedCategoryFilter == cat;
      final ft = _foodTypeLabelFor(it);
      final ftOk = selectedFoodTypeFilter == null ||
          selectedFoodTypeFilter == 'All' ||
          selectedFoodTypeFilter == ft;
      return nameOk && catOk && ftOk;
    }).toList();

    // right side counts for selected items
    final Map<String, int> rightCategoryCounts = {};
    final Map<String, int> rightFoodTypeCounts = {};
    for (final it
        in _items.where((i) => _selectedItemIds.contains(i.menuItemId))) {
      final cat =
          _categoryLabelFor(it).isEmpty ? 'Other' : _categoryLabelFor(it);
      rightCategoryCounts[cat] = (rightCategoryCounts[cat] ?? 0) + 1;
      final ft =
          _foodTypeLabelFor(it).isEmpty ? 'Other' : _foodTypeLabelFor(it);
      rightFoodTypeCounts[ft] = (rightFoodTypeCounts[ft] ?? 0) + 1;
    }

    final bool showSeeMore = filtered.length > 6;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1120,
        height: 760,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Expanded(
                  child: Text('Select menu & dishes',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              SizedBox(
                width: 420,
                child: Container(
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Menu',
                      labelStyle: GoogleFonts.poppins(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _menuId,
                        isExpanded: true,
                        items: menus
                            .map((m) => DropdownMenuItem(
                                value: m.id,
                                child:
                                    Text(m.name, style: GoogleFonts.poppins())))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _menuId = value;
                            _menu =
                                menus.firstWhereOrNull((m) => m.id == value);
                            _items = [];
                            _selectedItemIds.clear();
                          });
                          _loadItems(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // filter row
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]),
                child: TextField(
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search dish name, e.g. "rice"',
                    hintStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 200,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]),
              child: DropdownButtonFormField<String?>(
                value: selectedCategoryFilter,
                hint: Text('Category', style: GoogleFonts.poppins()),
                items: [null, 'All', ...allCategories]
                    .map((c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c ?? 'All', style: GoogleFonts.poppins())))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategoryFilter = v),
                decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
              ),
            ),
            const SizedBox(width: 12),
            Row(children: [
              _filterPill(
                  'Veg',
                  selectedFoodTypeFilter == 'Veg',
                  () => setState(() => selectedFoodTypeFilter =
                      selectedFoodTypeFilter == 'Veg' ? null : 'Veg')),
              const SizedBox(width: 8),
              _filterPill(
                  'Non-Veg',
                  selectedFoodTypeFilter == 'Non-Veg',
                  () => setState(() => selectedFoodTypeFilter =
                      selectedFoodTypeFilter == 'Non-Veg' ? null : 'Non-Veg')),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: TextButton(
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10)),
                  onPressed: () => setState(() {
                    search = '';
                    selectedCategoryFilter = null;
                    selectedFoodTypeFilter = null;
                  }),
                  child: Text('Clear',
                      style: GoogleFonts.poppins(color: Colors.black)),
                ),
              ),
            ]),
          ]),

          const SizedBox(height: 12),

          // body
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // LEFT
              Expanded(
                flex: 3,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        ...leftFoodTypeCounts.entries.map((e) => _infoChip(
                            '${e.key} • ${e.value}',
                            highlight: e.key.toLowerCase() == 'veg',
                            negative: e.key.toLowerCase().contains('non'))),
                        ...leftCategoryCounts.entries
                            .map((e) => _infoChip('${e.key} • ${e.value}')),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE6E9EE))),
                          child: _loadingItems
                              ? const Center(child: CircularProgressIndicator())
                              : filtered.isEmpty
                                  ? Center(
                                      child: Text('No items match your filters',
                                          style: GoogleFonts.poppins(
                                              color: Colors.grey)))
                                  : Column(children: [
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _leftScrollController,
                                          thumbVisibility: true,
                                          child: ListView.separated(
                                            controller: _leftScrollController,
                                            itemCount: filtered.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 10),
                                            itemBuilder: (_, idx) {
                                              final item = filtered[idx];
                                              final isSelected =
                                                  _selectedItemIds.contains(
                                                      item.menuItemId);
                                              final bool isVeg =
                                                  (_categoryLabelFor(item)
                                                          .toLowerCase()
                                                          .contains('veg') ||
                                                      _foodTypeLabelFor(item)
                                                              .toLowerCase() ==
                                                          'veg');

                                              return InkWell(
                                                onTap: () =>
                                                    _toggleSelection(item),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? (isVeg
                                                            ? Colors
                                                                .green.shade50
                                                            : Colors
                                                                .red.shade50)
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: isSelected
                                                            ? (isVeg
                                                                ? Colors.green
                                                                    .shade700
                                                                : Colors.red
                                                                    .shade700)
                                                            : Colors
                                                                .grey.shade300),
                                                  ),
                                                  child: Row(children: [
                                                    _foodSquareIcon(isVeg),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(item.name,
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700)),
                                                            const SizedBox(
                                                                height: 6),
                                                            Text(
                                                              [
                                                                if (_foodTypeLabelFor(
                                                                        item)
                                                                    .isNotEmpty)
                                                                  _foodTypeLabelFor(
                                                                      item),
                                                                if (_categoryLabelFor(
                                                                        item)
                                                                    .isNotEmpty)
                                                                  _categoryLabelFor(
                                                                      item)
                                                              ].join(' • '),
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade700),
                                                            ),
                                                          ]),
                                                    ),
                                                    Text(
                                                        _currency.format(
                                                            _priceOf(item)),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? Colors.black
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color: Colors.grey
                                                                  .shade300)),
                                                      child: TextButton(
                                                        style: TextButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        10)),
                                                        onPressed: () =>
                                                            _toggleSelection(
                                                                item),
                                                        child: Text(
                                                            isSelected
                                                                ? 'Remove'
                                                                : 'Add',
                                                            style: GoogleFonts.poppins(
                                                                color: isSelected
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)),
                                                      ),
                                                    )
                                                  ]),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (showSeeMore)
                                        Container(
                                          alignment: Alignment.center,
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            onPressed: () {
                                              final max = _leftScrollController
                                                  .position.maxScrollExtent;
                                              final pos =
                                                  _leftScrollController.offset +
                                                      260;
                                              _leftScrollController.animateTo(
                                                  pos.clamp(0, max),
                                                  duration: const Duration(
                                                      milliseconds: 420),
                                                  curve: Curves.easeInOut);
                                            },
                                            child: Text('See more',
                                                style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ),
                                    ]),
                        ),
                      ),
                    ]),
              ),

              const SizedBox(width: 18),

              // RIGHT
              Expanded(
                flex: 2,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected header + total count displayed separately
                      Text.rich(
                        TextSpan(
                          text: 'Selected items - ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: '${_selectedItemIds.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Selected summary chips
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: Wrap(spacing: 8, children: [
                          _infoChip('Total • ${_selectedItemIds.length}'),
                          ...rightFoodTypeCounts.entries.map((e) => _infoChip(
                              '${e.key} • ${e.value}',
                              highlight: e.key.toLowerCase() == 'veg',
                              negative: e.key.toLowerCase().contains('non'))),
                          ...rightCategoryCounts.entries
                              .map((e) => _infoChip('${e.key} • ${e.value}')),
                        ]),
                      ),

                      const SizedBox(height: 8),

                      // selected list
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB))),
                          child: _items
                                  .where((i) =>
                                      _selectedItemIds.contains(i.menuItemId))
                                  .isEmpty
                              ? Center(
                                  child: Text('No items selected yet.',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey)))
                              : Scrollbar(
                                  controller: _rightScrollController,
                                  thumbVisibility: true,
                                  child: ListView.builder(
                                    controller: _rightScrollController,
                                    itemCount: _items
                                        .where((i) => _selectedItemIds
                                            .contains(i.menuItemId))
                                        .length,
                                    itemBuilder: (_, index) {
                                      final selectedList = _items
                                          .where((i) => _selectedItemIds
                                              .contains(i.menuItemId))
                                          .toList();
                                      final it = selectedList[index];
                                      final price = _priceOf(it);
                                      final ft = _foodTypeLabelFor(it);
                                      final cat = _categoryLabelFor(it);
                                      final isVeg = ft.toLowerCase() == 'veg';
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFE5E7EB))),
                                        child: Row(children: [
                                          _foodSquareIcon(isVeg),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(it.name,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700)),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                      [
                                                        if (ft.isNotEmpty) ft,
                                                        if (cat.isNotEmpty) cat
                                                      ].join(' • '),
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade700)),
                                                ]),
                                          ),
                                          Text(_currency.format(price),
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700)),
                                          IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18),
                                              onPressed: () => setState(() =>
                                                  _selectedItemIds
                                                      .remove(it.menuItemId))),
                                        ]),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // total + actions
                      // --- Replace the existing total + actions row with this "bill" footer ---
                      // ---------- SNIPPET A: selected-items mini footer (centered, pill style) ----------
                      const SizedBox(height: 10),

// Centered pills (Items count + Total) inside the selected-items panel
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        // keep it visually separated but subtle
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Items pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text('Items:',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Text('${_selectedItemIds.length}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Total pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text('Total',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 10),
                                  Text(_currency.format(_selectedTotal),
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 10),

          // --- GLOBAL ACTION ROW AT THE BOTTOM OF POPUP ---
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Confirm
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(String text,
      {bool highlight = false, bool negative = false}) {
    final bg = highlight
        ? Colors.green.shade50
        : (negative ? Colors.red.shade50 : Colors.grey.shade50);
    final border = highlight
        ? Colors.green.shade200
        : (negative ? Colors.red.shade200 : Colors.grey.shade200);
    final color = highlight
        ? Colors.green.shade800
        : (negative ? Colors.red.shade800 : Colors.black87);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border)),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)));
  }

  Widget _filterPill(String text, bool selected, VoidCallback onTap) {
    final bool isVeg = text.toLowerCase().contains('veg') &&
        !text.toLowerCase().contains('non');
    final bool isNon = text.toLowerCase().contains('non');
    final bg = selected
        ? (isVeg
            ? Colors.green.shade900
            : (isNon ? Colors.red.shade900 : Colors.black))
        : Colors.white;
    final fg = selected
        ? Colors.white
        : (isVeg
            ? Colors.green.shade900
            : (isNon ? Colors.red.shade900 : Colors.black));
    final borderColor = selected ? bg : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 4))
                  ]
                : null),
        child: Text(text,
            style: GoogleFonts.poppins(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _foodSquareIcon(bool isVeg) {
    final color = isVeg ? Colors.green : Colors.red;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4)),
      child: Center(
          child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(1.5)))),
    );
  }

  // Small helpers used in this dialog (string-safe, no casts)
  String _foodTypeLabelFor(MenuItem item) {
    final dynamic ft = item.foodType;
    if (ft == null) return '';

    String raw;
    if (ft is FoodType) {
      raw = ft.name;
    } else if (ft is String) {
      raw = ft;
    } else {
      raw = ft.toString();
    }

    final last = raw.split('.').last.replaceAll('_', '').trim().toLowerCase();

    if (last.contains('non')) return 'Non-Veg';
    if (last.contains('veg')) return 'Veg';
    if (last.isEmpty) return '';
    return last[0].toUpperCase() + last.substring(1);
  }

  String _categoryLabelFor(MenuItem item) {
    final dynamic c = item.category;
    if (c == null) return '';

    String raw;
    if (c is MenuCategory) {
      raw = c.name;
    } else if (c is String) {
      raw = c;
    } else {
      raw = c.toString();
    }

    final last = raw.split('.').last.replaceAll('_', ' ').trim();
    if (last.isEmpty) return '';
    return _titleCase(last);
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
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

class GuestListSection extends StatelessWidget {
  const GuestListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminGuestListController controller =
        Get.find<AdminGuestListController>();

    final EventController eventController = Get.find<EventController>();
    final CloudFunctionsService cloudFunctions =
        Get.find<CloudFunctionsService>();

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
          // ---------------------------
          // HEADER
          // ---------------------------
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

              // ADD GUEST BUTTON
              AppPrimaryButton(
                onPressed: () {
                  controller.clearForm();
                  showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AddGuestPopup(controller: controller),
                  ).then((added) {
                    if (added == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guest added')),
                      );
                    }
                    controller.clearForm();
                  });
                },
                text: '+ Add Guest',
              ),

              const SizedBox(width: 12),

              // SEND INVITATION BUTTON
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 0,
                  maxWidth: 200, // prevents infinite width
                ),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(
                    'Send invitation',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final event = eventController.selectedEvent.value;
                    if (event == null || event.eventId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select an event first')),
                      );
                      return;
                    }

                    final guests = controller.filteredGuests;
                    if (guests.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No guests to invite')),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Send invitations'),
                        content: Text(
                            'Send invitations to ${guests.length} guest(s)?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Send')),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    // show loader
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: true,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final result = await cloudFunctions
                          .sendInvitationsForEvent(event, guests: guests);

                      // close loader
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      final invitedCount = result['invited'] ?? guests.length;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Invitations sent to $invitedCount guest(s)')),
                      );
                    } on FirebaseFunctionsException catch (fe) {
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                      final msg =
                          fe.message ?? 'Cloud function error: ${fe.code}';
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    } catch (e) {
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error sending invitations: $e')));
                    }
                  },
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          // ---------------------------
          // TABLE BODY
          // ---------------------------
          Obx(() {
            if (!controller.isInitialized.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final list = controller.filteredGuests;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No guests yet. Click "Add Guest" to create one.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('City')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: list.map((guest) {
                  return DataRow(
                    cells: [
                      DataCell(Text(guest.name)),
                      DataCell(Text(guest.email ?? '—')),
                      DataCell(Text(guest.city ?? '—')),
                      DataCell(Text(guest.country ?? '—')),
                      DataCell(Text(
                        guest.gender?.name ?? '—',
                      )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () {
                                controller.updateAllFields(guest);
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AddGuestPopup(
                                    controller: controller,
                                    isEditMode: true,
                                  ),
                                ).then((_) => controller.clearForm());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete guest?'),
                                    content: Text('Delete "${guest.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Delete'),
                                      )
                                    ],
                                  ),
                                );
                                if (ok == true && guest.guestId != null) {
                                  await controller.deleteGuest(guest.guestId!);
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
            );
          }),
        ],
      ),
    );
  }
}
