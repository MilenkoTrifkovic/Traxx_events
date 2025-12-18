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
import 'package:traxx_wepapp/widgets/app_currency.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_photo_manager.dart';

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

  /// Optional: if you still want the callback style.
  final ValueChanged<QuestionSet>? onSelected;

  const DemographicSetPickerDialog({
    super.key,
    required this.sets,
    this.onSelected,
  });

  @override
  State<DemographicSetPickerDialog> createState() =>
      _DemographicSetPickerDialogState();
}

class _DemographicSetPickerDialogState
    extends State<DemographicSetPickerDialog> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  String _search = '';
  QuestionSet? _selected;

  @override
  void initState() {
    super.initState();
    // default selection
    if (widget.sets.isNotEmpty) {
      _selected = widget.sets.first;
    }
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  List<QuestionSet> get _filteredSets {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return widget.sets;

    return widget.sets.where((s) {
      final t = (s.title).toLowerCase();
      final d = (s.description).toLowerCase();
      final id = (s.questionSetId).toLowerCase();
      return t.contains(q) || d.contains(q) || id.contains(q);
    }).toList();
  }

  void _pick(QuestionSet s) {
    setState(() => _selected = s);
    if (_rightScrollController.hasClients) {
      _rightScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _confirm() {
    final s = _selected;
    if (s == null) return;

    // If caller provided callback, fire it
    widget.onSelected?.call(s);

    // Always return selected for callers who await showDialog()
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final sets = _filteredSets;
    final selected = _selected;

    final totalCount = widget.sets.length;
    final filteredCount = sets.length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1240,
        height: 820,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // HEADER (matches your dishes popup feel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select demographic question set',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // SEARCH ROW
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search set name, description, or id…',
                      hintStyle: GoogleFonts.poppins(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                _infoChip('Total • $totalCount'),
                const SizedBox(width: 8),
                _infoChip(
                  'Showing • $filteredCount',
                  highlight: _search.trim().isNotEmpty,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT LIST
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6E9EE)),
                      ),
                      child: sets.isEmpty
                          ? Center(
                              child: Text(
                                'No sets match your search',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            )
                          : Scrollbar(
                              controller: _leftScrollController,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _leftScrollController,
                                itemCount: sets.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, idx) {
                                  final s = sets[idx];
                                  final isSelected = selected?.questionSetId ==
                                      s.questionSetId;

                                  return InkWell(
                                    onTap: () => _pick(s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.blue.shade600
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.assignment_outlined,
                                              size: 18,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                if (s.description.isNotEmpty)
                                                  Text(
                                                    s.description,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'No description',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          TextButton(
                                            onPressed: () {
                                              _pick(s);
                                              _confirm();
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: isSelected
                                                  ? Colors.black
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              isSelected ? 'Selected' : 'Pick',
                                              style: GoogleFonts.poppins(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  // RIGHT PREVIEW
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: selected == null
                          ? Center(
                              child: Text(
                                'Select a set to preview',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            )
                          : Scrollbar(
                              controller: _rightScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _rightScrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Preview',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selected.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (selected.description.isNotEmpty)
                                            Text(
                                              selected.description,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            )
                                          else
                                            Text(
                                              'No description provided.',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tip: You can change this later anytime.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // FOOTER ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selected == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniKeyValue(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '$k:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
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
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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
    final initialMenuId = controller.lastBrowsedMenuId.value ??
        (controller.availableMenus.isNotEmpty
            ? controller.availableMenus.first.id
            : null);

    await showDialog(
      context: context,
      builder: (_) => MenuAndItemsDialog(
        controller: controller,
        initialMenuId: initialMenuId,
        initialItemIds: controller.selectedMenuItemIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIds = controller.selectedMenuItemIds.toList();
      final selectedItems = controller.selectedMenuItems.toList();

      final bool hasSelection = selectedIds.isNotEmpty;
      final bool isLoadingSelectedDocs = hasSelection && selectedItems.isEmpty;

      double priceOf(MenuItem item) {
        final p = item.price;
        if (p == null) return 0.0;
        if (p is num) return p.toDouble();
        return double.tryParse(p.toString()) ?? 0.0;
      }

      final total = selectedItems.map(priceOf).fold(0.0, (a, b) => a + b);

      // counts
      final Map<String, int> typeCounts = {};
      final Map<String, int> catCounts = {};
      for (final i in selectedItems) {
        final ft = _foodTypeLabel(i).isEmpty ? 'Other' : _foodTypeLabel(i);
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  tooltip: hasSelection ? 'Edit selection' : 'Select dishes',
                  icon: Icon(hasSelection ? Icons.edit_outlined : Icons.add),
                  onPressed: () => _openMenuDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!hasSelection) ...[
              Text(
                'No dishes selected for this event.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _openMenuDialog(context),
                child: Text('Select dishes', style: GoogleFonts.poppins()),
              ),
            ] else if (isLoadingSelectedDocs) ...[
              // ✅ Handles the “IDs exist but docs are still loading” state
              Text(
                'Loading selected dishes...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ] else ...[
              // ✅ IMPORTANT: no menu name/description shown (items are mixed)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _summaryChip('Total', selectedIds.length),
                  ...typeCounts.entries
                      .map((e) => _summaryChip(e.key, e.value)),
                  ...catCounts.entries.map((e) => _summaryChip(e.key, e.value)),
                ],
              ),
              const SizedBox(height: 10),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    itemCount: selectedItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) =>
                        selectedDishRow(selectedItems[idx]),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppCurrency.format(total),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        border: Border.all(color: border),
      ),
      child: Text(
        '$label • $count',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget selectedDishRow(MenuItem item) {
    final String ftLabel = _foodTypeLabel(item);
    final String catLabel = _categoryLabel(item);
    final bool isVeg = ftLabel.toLowerCase() == 'veg' || _isVegByCategory(item);

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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                ),
              ],
            ),
          ),
          Text(
            AppCurrency.format(p),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _foodTypeLabel(MenuItem item) {
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

  String _categoryLabel(MenuItem item) {
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
  List<MenuItem> _items = [];

  // keep order (newest at top)
  final List<String> _selectedOrder = [];
  final Set<String> _selectedIds = {};
  final Map<String, MenuItem> _selectedCache = {};

  bool _loadingItems = false;
  bool _loadingSelected = false;
  bool _saving = false;

  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  final TextEditingController _leftSearchCtrl = TextEditingController();
  final TextEditingController _rightSearchCtrl = TextEditingController();

  String _leftSearch = '';
  String _rightSearch = '';

  String? _leftCategory; // null = All
  String? _rightCategory; // null = All

  FoodType? _leftFoodType; // null = All
  FoodType? _rightFoodType;

  @override
  void initState() {
    super.initState();

    _menuId = widget.initialMenuId ??
        widget.controller.lastBrowsedMenuId.value ??
        (widget.controller.availableMenus.isNotEmpty
            ? widget.controller.availableMenus.first.id
            : null);

    // init selection (preserve stored order)
    for (final id in widget.initialItemIds) {
      final v = id.trim();
      if (v.isEmpty) continue;
      if (_selectedIds.add(v)) _selectedOrder.add(v);
    }

    _prefetchSelectedDetails();

    if (_menuId != null) {
      _loadItems(_menuId!);
    }
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _leftSearchCtrl.dispose();
    _rightSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefetchSelectedDetails() async {
    if (_selectedOrder.isEmpty) return;
    setState(() => _loadingSelected = true);
    try {
      final list =
          await widget.controller.fetchMenuItemsByIds(_selectedOrder.toList());
      for (final it in list) {
        final id = (it.menuItemId ?? '').trim();
        if (id.isNotEmpty) _selectedCache[id] = it;
      }
    } finally {
      if (mounted) setState(() => _loadingSelected = false);
    }
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

  // ✅ robust foodType: uses item.foodType first, then falls back to item.isVeg if present.
  FoodType? _foodTypeFor(MenuItem item) {
    // 1) if your model has foodType
    final dynamic ft = (item as dynamic).foodType;
    if (ft is FoodType) return ft;

    // 2) if foodType stored as String somehow
    if (ft is String) {
      final norm = ft.replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase();
      if (norm == 'veg') return FoodType.veg;
      if (norm == 'nonveg') return FoodType.nonVeg;
    }

    // 3) fallback to isVeg field if present on model
    final dynamic v = (item as dynamic).isVeg;
    if (v is bool) return v ? FoodType.veg : FoodType.nonVeg;

    return null; // unknown
  }

  String _foodTypeLabelFor(MenuItem item) {
    final ft = _foodTypeFor(item);
    if (ft == FoodType.veg) return 'Veg';
    if (ft == FoodType.nonVeg) return 'Non-Veg';
    return ''; // unknown
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

    // ✅ handle enum.toString + camelCase nicely
    var last = raw.split('.').last.trim();
    last = last.replaceAll('_', ' ');
    last = last.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
    last = last.trim();

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

  void _addToTop(String id) {
    if (_selectedIds.add(id)) {
      _selectedOrder.insert(0, id);
    } else {
      _selectedOrder.remove(id);
      _selectedOrder.insert(0, id);
    }
  }

  void _removeId(String id) {
    _selectedIds.remove(id);
    _selectedOrder.remove(id);
    _selectedCache.remove(id);
  }

  Future<void> _toggleSelection(MenuItem item) async {
    final id = (item.menuItemId ?? '').trim();
    if (id.isEmpty) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _removeId(id);
      } else {
        _addToTop(id);
        _selectedCache[id] = item;
      }
    });

    if (_rightScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _rightScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }

    if (_selectedIds.contains(id) && _selectedCache[id] == null) {
      final fetched = await widget.controller.fetchMenuItemById(id);
      if (fetched != null && mounted) {
        setState(() => _selectedCache[id] = fetched);
      }
    }
  }

  List<MenuItem> get _selectedItemsOrdered {
    final out = <MenuItem>[];
    for (final id in _selectedOrder) {
      final it = _selectedCache[id];
      if (it != null) out.add(it);
    }
    return out;
  }

  double get _selectedTotal =>
      _selectedItemsOrdered.map(_priceOf).fold(0.0, (a, b) => a + b);

  Widget _buildHeader(BuildContext context, List<MenuModel> menus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select menu & dishes',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 460,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Menu (browse)',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _menuId,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  iconEnabledColor: Colors.white,

                  // ✅ FIX: selected text in the field should be WHITE
                  selectedItemBuilder: (_) => menus
                      .map((m) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              m.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),

                  // ✅ dropdown list should stay BLACK text on WHITE bg
                  items: menus
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              m.name,
                              style: GoogleFonts.poppins(color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _menuId = value;
                      _items = [];
                    });

                    widget.controller.lastBrowsedMenuId.value = value;
                    _loadItems(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = widget.controller.availableMenus;

    String _norm(String s) =>
        s.replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase();

    // LEFT menu categories based on current menu
    final allCategories = _items
        .map(_categoryLabelFor)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final Map<String, int> leftCategoryCounts = {};
    final Map<String, int> leftFoodTypeCounts = {}; // Veg / Non-Veg / Other

    for (final it in _items) {
      final cat =
          _categoryLabelFor(it).isEmpty ? 'Other' : _categoryLabelFor(it);
      leftCategoryCounts[cat] = (leftCategoryCounts[cat] ?? 0) + 1;

      final ftLabel = _foodTypeLabelFor(it);
      final key = ftLabel.isEmpty ? 'Other' : ftLabel;
      leftFoodTypeCounts[key] = (leftFoodTypeCounts[key] ?? 0) + 1;
    }

    // LEFT filtered list
    final filteredLeft = _items.where((it) {
      final q = _leftSearch.toLowerCase().trim();
      final nameOk = q.isEmpty || it.name.toLowerCase().contains(q);

      final cat = _categoryLabelFor(it);
      final catOk = _leftCategory == null || _leftCategory == cat;

      final ft = _foodTypeFor(it);
      final ftOk = _leftFoodType == null || ft == _leftFoodType;

      return nameOk && catOk && ftOk;
    }).toList();

    // RIGHT counts (selected)
    final selectedOrdered = _selectedItemsOrdered;

    final Map<String, int> rightCategoryCounts = {};
    final Map<String, int> rightFoodTypeCounts = {};

    for (final it in selectedOrdered) {
      final cat =
          _categoryLabelFor(it).isEmpty ? 'Other' : _categoryLabelFor(it);
      rightCategoryCounts[cat] = (rightCategoryCounts[cat] ?? 0) + 1;

      final ftLabel = _foodTypeLabelFor(it);
      final key = ftLabel.isEmpty ? 'Other' : ftLabel;
      rightFoodTypeCounts[key] = (rightFoodTypeCounts[key] ?? 0) + 1;
    }

    final bool showSeeMore = filteredLeft.length > 6;

    return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.08), // try 1.06–1.10
        ),
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 1240,
            height: 820,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildHeader(context, menus),
                // filter row
                // Row(
                //   children: [
                //     Expanded(
                //       child: TextField(
                //         style: GoogleFonts.poppins(),
                //         decoration: InputDecoration(
                //           prefixIcon: const Icon(Icons.search),
                //           hintText: 'Search dish name, e.g. "rice"',
                //           hintStyle: GoogleFonts.poppins(),
                //           filled: true,
                //           fillColor: Colors.white,
                //           border: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(10),
                //             borderSide: BorderSide.none,
                //           ),
                //           contentPadding: const EdgeInsets.symmetric(
                //               horizontal: 12, vertical: 12),
                //         ),
                //         onChanged: (v) => setState(() => _leftSearch = v),
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     SizedBox(
                //       width: 200,
                //       child: DropdownButtonFormField<String?>(
                //         value: _leftCategory,
                //         hint: Text('Category', style: GoogleFonts.poppins()),
                //         items: [null, 'All', ...allCategories]
                //             .map((c) => DropdownMenuItem<String?>(
                //                   value: c,
                //                   child: Text(c ?? 'All',
                //                       style: GoogleFonts.poppins()),
                //                 ))
                //             .toList(),
                //         onChanged: (v) => setState(() => _leftCategory = v),
                //         decoration: InputDecoration(
                //           fillColor: Colors.white,
                //           filled: true,
                //           border: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(10),
                //             borderSide: BorderSide.none,
                //           ),
                //           contentPadding: const EdgeInsets.symmetric(
                //               horizontal: 12, vertical: 8),
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Row(
                //       children: [
                //         _filterPill(
                //           'Veg',
                //           _leftFoodType == FoodType.veg,
                //           () => setState(() => _leftFoodType =
                //               _leftFoodType == FoodType.veg ? null : FoodType.veg),
                //         ),
                //         _filterPill(
                //           'Non-Veg',
                //           _leftFoodType == FoodType.nonVeg,
                //           () => setState(() => _leftFoodType =
                //               _leftFoodType == FoodType.nonVeg
                //                   ? null
                //                   : FoodType.nonVeg),
                //         ),
                //         const SizedBox(width: 12),
                //         TextButton(
                //           onPressed: () => setState(() {
                //             _leftSearch = '';
                //             _leftCategory = null;
                //             _leftFoodType = null;
                //           }),
                //           child: Text('Clear',
                //               style: GoogleFonts.poppins(color: Colors.black)),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),

                const SizedBox(height: 18),

                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 18, 24, 24), // spacing for body
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= LEFT HALF (Before selection) =================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Veg/Non-Veg counts (ONLY)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Before selection',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _infoChip(
                                  'Veg • ${_items.where((it) => _foodTypeFor(it) == FoodType.veg).length}',
                                  highlight: true,
                                ),
                                const SizedBox(width: 8),
                                _infoChip(
                                  'Non-Veg • ${_items.where((it) => _foodTypeFor(it) == FoodType.nonVeg).length}',
                                  negative: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // LEFT filters (moved fully to left)
                            TextField(
                              controller: _leftSearchCtrl,
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'Search dish name, e.g. "rice"',
                                hintStyle: GoogleFonts.poppins(),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              onChanged: (v) => setState(() => _leftSearch = v),
                            ),
                            const SizedBox(height: 10),

                            Builder(builder: (_) {
                              // category counts for LEFT dropdown (from all _items)
                              final Map<String, int> leftCatCounts = {};
                              for (final it in _items) {
                                final cat = _categoryLabelFor(it).isEmpty
                                    ? 'Other'
                                    : _categoryLabelFor(it);
                                leftCatCounts[cat] =
                                    (leftCatCounts[cat] ?? 0) + 1;
                              }
                              final leftCats = leftCatCounts.keys.toList()
                                ..sort();

                              return Row(
                                children: [
                                  SizedBox(
                                    width: 260,
                                    child: DropdownButtonFormField<String?>(
                                      value: _leftCategory,
                                      hint: Text('Category',
                                          style: GoogleFonts.poppins()),
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('All (${_items.length})',
                                              style: GoogleFonts.poppins()),
                                        ),
                                        ...leftCats.map((c) =>
                                            DropdownMenuItem<String?>(
                                              value: c,
                                              child: Text(
                                                  '$c (${leftCatCounts[c] ?? 0})',
                                                  style: GoogleFonts.poppins()),
                                            )),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _leftCategory = v),
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _filterPill(
                                    'Veg',
                                    _leftFoodType == FoodType.veg,
                                    () => setState(() => _leftFoodType =
                                        _leftFoodType == FoodType.veg
                                            ? null
                                            : FoodType.veg),
                                  ),
                                  const SizedBox(width: 8),
                                  _filterPill(
                                    'Non-Veg',
                                    _leftFoodType == FoodType.nonVeg,
                                    () => setState(() => _leftFoodType =
                                        _leftFoodType == FoodType.nonVeg
                                            ? null
                                            : FoodType.nonVeg),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _leftSearchCtrl.clear();
                                      _leftSearch = '';
                                      _leftCategory = null;
                                      _leftFoodType = null;
                                    }),
                                    child: Text('Clear',
                                        style: GoogleFonts.poppins(
                                            color: Colors.black)),
                                  ),
                                ],
                              );
                            }),

                            const SizedBox(height: 10),

                            // LEFT list container
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFE6E9EE)),
                                ),
                                child: Builder(builder: (_) {
                                  final filteredLeft = _items.where((it) {
                                    final q = _leftSearch.toLowerCase().trim();
                                    final nameOk = q.isEmpty ||
                                        it.name.toLowerCase().contains(q);

                                    final cat = _categoryLabelFor(it);
                                    final catOk = _leftCategory == null ||
                                        _leftCategory == cat;

                                    final ft = _foodTypeFor(it);
                                    final ftOk = _leftFoodType == null ||
                                        ft == _leftFoodType;

                                    return nameOk && catOk && ftOk;
                                  }).toList();

                                  final bool showSeeMore =
                                      filteredLeft.length > 6;

                                  if (_loadingItems) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (filteredLeft.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No items match your filters',
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _leftScrollController,
                                          thumbVisibility: true,
                                          child: ListView.separated(
                                            controller: _leftScrollController,
                                            itemCount: filteredLeft.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 10),
                                            itemBuilder: (_, idx) {
                                              final item = filteredLeft[idx];
                                              final id = (item.menuItemId ?? '')
                                                  .trim();
                                              final isSelected =
                                                  id.isNotEmpty &&
                                                      _selectedIds.contains(id);
                                              final bool isVeg =
                                                  _foodTypeFor(item) ==
                                                      FoodType.veg;

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
                                                              : Colors
                                                                  .red.shade700)
                                                          : Colors
                                                              .grey.shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      _foodSquareIcon(isVeg),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item.name,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
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
                                                                      item),
                                                              ].join(' • '),
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        AppCurrency.format(
                                                            _priceOf(item)),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? Colors.black
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color: Colors.grey
                                                                  .shade300),
                                                        ),
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              _toggleSelection(
                                                                  item),
                                                          child: Text(
                                                            isSelected
                                                                ? 'Remove'
                                                                : 'Add',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                                    BorderRadius.circular(8),
                                              ),
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
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                            child: Text(
                                              'See more',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),
                      Container(
                          width: 1,
                          height: double.infinity,
                          color: const Color(0xFFE5E7EB)),
                      const SizedBox(width: 20),

                      // ================= RIGHT HALF (After selection) =================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Build selected list ids filtered by RIGHT filters
                            Builder(builder: (_) {
                              final bool rightFiltersActive =
                                  _rightSearch.trim().isNotEmpty ||
                                      _rightCategory != null ||
                                      _rightFoodType != null;

                              bool match(MenuItem it) {
                                final q = _rightSearch.toLowerCase().trim();
                                final nameOk = q.isEmpty ||
                                    it.name.toLowerCase().contains(q);

                                final cat = _categoryLabelFor(it);
                                final catOk = _rightCategory == null ||
                                    _rightCategory == cat;

                                final ft = _foodTypeFor(it);
                                final ftOk = _rightFoodType == null ||
                                    ft == _rightFoodType;

                                return nameOk && catOk && ftOk;
                              }

                              final visibleSelectedIds = <String>[];
                              for (final id in _selectedOrder) {
                                final it = _selectedCache[id];
                                if (it == null) {
                                  // show loading cards only when no right filters are applied
                                  if (!rightFiltersActive)
                                    visibleSelectedIds.add(id);
                                  continue;
                                }
                                if (match(it)) visibleSelectedIds.add(id);
                              }

                              final visibleItems = visibleSelectedIds
                                  .map((id) => _selectedCache[id])
                                  .whereType<MenuItem>()
                                  .toList();

                              final vegCount = visibleItems
                                  .where(
                                      (it) => _foodTypeFor(it) == FoodType.veg)
                                  .length;
                              final nonCount = visibleItems
                                  .where((it) =>
                                      _foodTypeFor(it) == FoodType.nonVeg)
                                  .length;

                              // category counts for RIGHT dropdown (from all selected, not filtered)
                              final Map<String, int> rightCatCounts = {};
                              for (final it in _selectedItemsOrdered) {
                                final cat = _categoryLabelFor(it).isEmpty
                                    ? 'Other'
                                    : _categoryLabelFor(it);
                                rightCatCounts[cat] =
                                    (rightCatCounts[cat] ?? 0) + 1;
                              }
                              final rightCats = rightCatCounts.keys.toList()
                                ..sort();

                              return Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + counts only
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Selected Items - ${_selectedOrder.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        _infoChip('Veg • $vegCount',
                                            highlight: true),
                                        const SizedBox(width: 8),
                                        _infoChip('Non-Veg • $nonCount',
                                            negative: true),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // RIGHT filters (new, only for selected items)
                                    TextField(
                                      controller: _rightSearchCtrl,
                                      style: GoogleFonts.poppins(),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.search),
                                        hintText:
                                            'Search within selected items',
                                        hintStyle: GoogleFonts.poppins(),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _rightSearch = v),
                                    ),
                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 260,
                                          child:
                                              DropdownButtonFormField<String?>(
                                            value: _rightCategory,
                                            hint: Text('Category',
                                                style: GoogleFonts.poppins()),
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text(
                                                  'All (${_selectedOrder.length})',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                              ...rightCats.map((c) =>
                                                  DropdownMenuItem<String?>(
                                                    value: c,
                                                    child: Text(
                                                      '$c (${rightCatCounts[c] ?? 0})',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                  )),
                                            ],
                                            onChanged: (v) => setState(
                                                () => _rightCategory = v),
                                            decoration: InputDecoration(
                                              fillColor: Colors.white,
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _filterPill(
                                          'Veg',
                                          _rightFoodType == FoodType.veg,
                                          () => setState(() => _rightFoodType =
                                              _rightFoodType == FoodType.veg
                                                  ? null
                                                  : FoodType.veg),
                                        ),
                                        const SizedBox(width: 8),
                                        _filterPill(
                                          'Non-Veg',
                                          _rightFoodType == FoodType.nonVeg,
                                          () => setState(() => _rightFoodType =
                                              _rightFoodType == FoodType.nonVeg
                                                  ? null
                                                  : FoodType.nonVeg),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => setState(() {
                                            _rightSearchCtrl.clear();
                                            _rightSearch = '';
                                            _rightCategory = null;
                                            _rightFoodType = null;
                                          }),
                                          child: Text('Clear',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.black)),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // RIGHT list
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: _loadingSelected
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : visibleSelectedIds.isEmpty
                                                ? Center(
                                                    child: Text(
                                                      'No selected items match your filters',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color:
                                                                  Colors.grey),
                                                    ),
                                                  )
                                                : Scrollbar(
                                                    controller:
                                                        _rightScrollController,
                                                    thumbVisibility: true,
                                                    child: ListView.builder(
                                                      controller:
                                                          _rightScrollController,
                                                      itemCount:
                                                          visibleSelectedIds
                                                              .length,
                                                      itemBuilder: (_, index) {
                                                        final id =
                                                            visibleSelectedIds[
                                                                index];
                                                        final it =
                                                            _selectedCache[id];

                                                        if (it == null) {
                                                          return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 10),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        10),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border: Border.all(
                                                                  color: const Color(
                                                                      0xFFE5E7EB)),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const SizedBox(
                                                                  width: 18,
                                                                  height: 18,
                                                                  child: CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2),
                                                                ),
                                                                const SizedBox(
                                                                    width: 10),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Loading item...',
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade700,
                                                                    ),
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .close,
                                                                      size: 18),
                                                                  onPressed: () =>
                                                                      setState(() =>
                                                                          _removeId(
                                                                              id)),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }

                                                        final price =
                                                            _priceOf(it);
                                                        final bool isVeg =
                                                            _foodTypeFor(it) ==
                                                                FoodType.veg;
                                                        final ftLabel =
                                                            _foodTypeLabelFor(
                                                                it);
                                                        final cat =
                                                            _categoryLabelFor(
                                                                it);

                                                        return Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 10),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            border: Border.all(
                                                                color: const Color(
                                                                    0xFFE5E7EB)),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              _foodSquareIcon(
                                                                  isVeg),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      it.name,
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            6),
                                                                    Text(
                                                                      [
                                                                        if (ftLabel
                                                                            .isNotEmpty)
                                                                          ftLabel,
                                                                        if (cat
                                                                            .isNotEmpty)
                                                                          cat,
                                                                      ].join(
                                                                          ' • '),
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade700,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Text(
                                                                AppCurrency
                                                                    .format(
                                                                        price),
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                    Icons.close,
                                                                    size: 18),
                                                                onPressed: () =>
                                                                    setState(() =>
                                                                        _removeId(
                                                                            id)),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // totals (overall selection, not filtered)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Text('Items:',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade200),
                                                ),
                                                child: Text(
                                                    '${_selectedOrder.length}',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: Row(
                                            children: [
                                              Text('Total',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(width: 10),
                                              Text(
                                                  AppCurrency.format(
                                                      _selectedTotal),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: _saving
                                              ? null
                                              : () =>
                                                  Navigator.of(context).pop(),
                                          child: Text('Cancel',
                                              style: GoogleFonts.poppins()),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: _saving
                                              ? null
                                              : () async {
                                                  setState(
                                                      () => _saving = true);
                                                  try {
                                                    widget
                                                        .controller
                                                        .lastBrowsedMenuId
                                                        .value = _menuId;
                                                    await widget.controller
                                                        .applyMenuSelection(
                                                            _selectedOrder);
                                                    if (mounted)
                                                      Navigator.of(context)
                                                          .pop();
                                                  } finally {
                                                    if (mounted)
                                                      setState(() =>
                                                          _saving = false);
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black),
                                          child: _saving
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text('Confirm',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ));
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
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
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
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(color: fg, fontWeight: FontWeight.w600),
        ),
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

    final QuestionSet? picked = await showDialog<QuestionSet?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DemographicSetPickerDialog(sets: cleanedSets),
    );

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
