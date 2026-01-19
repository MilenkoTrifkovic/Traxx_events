import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/event_hosts_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/view/admin_guest_list.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/menu_item_group.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/menu_cateogory_utils.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/event_host_list_section.dart';
import 'package:traxx_wepapp/widgets/app_currency.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_photo_manager.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/venue_info_section/venue_section_card.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/event_summary_section.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/invitation_letter/invitation_letter_section.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/widgets/dialog_step_header.dart';

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

      final evt = controller.event.value;
      if (evt != null) {
        final tag = widget.eventId;

        if (!Get.isRegistered<EventHostsController>(tag: tag)) {
          Get.put(
            EventHostsController(
              eventDocId: widget.eventId, // ✅ use widget.eventId
              organisationId: evt
                  .organisationId, // ✅ needed for loadAvailableHosts + resend
            ),
            tag: tag,
          );
        }
      }

      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    Get.delete<EventHostsController>(tag: widget.eventId, force: true);
    Get.delete<AdminGuestListController>(force: true);
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

      // Calculate canInvite based on menu, demographics, and event status
      final hasDemo =
          (controller.selectedDemographicSetId.value ?? '').trim().isNotEmpty;
      final hasMenu = controller.selectedMenuItemIds.isNotEmpty;
      final isPublished = evt.status == EventStatus.published;
      final canInvite = hasDemo && hasMenu && isPublished;

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

            /// Row with Menu card + Demographic column (Demographic + Additional Info)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MenuSelectionCard(controller: controller),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      DemographicSelectionCard(controller: controller),
                      const SizedBox(height: 16),
                      Obx(() {
                        final event = controller.event.value;
                        if (event == null) return const SizedBox.shrink();
                        return InvitationLetterSection(event: event);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            EventAnalyzerCard(eventId: widget.eventId),

            const SizedBox(height: 24),

            /// Venue section
            // VenueSelectionCard(controller: controller),
            Row(children: [
              Expanded(child: VenueSelectionCard(controller: controller)),
            ]),
            const SizedBox(height: 24),

            EventHostsSection(tag: widget.eventId),

            const SizedBox(height: 24),

            /// Guest list section (keep Milenko’s logic, but inside a card)
            /// Guest list section class returned to Original Folder from line 1905-2080
            GuestListSection(
              eventName: evt.name,
              capacity: evt.capacity,
              canInvite: canInvite,
              maxInviteByGuest: evt.maxInviteByGuest,
            ),
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

  // ✅ Preview questions state
  bool _previewLoading = false;
  String? _previewError;
  List<_PreviewQuestion> _previewQuestions = const [];

  @override
  void initState() {
    super.initState();
    if (widget.sets.isNotEmpty) {
      _selected = widget.sets.first;
      _loadPreviewQuestions(_selected!.questionSetId);
    }
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  // ---------------------------
  // Safe helpers (avoid nullable/non-nullable mismatch)
  // ---------------------------
  String _descOf(QuestionSet s) {
    final d = (s as dynamic).description;
    return d == null ? '' : d.toString();
  }

  String _idOf(QuestionSet s) {
    final id = (s as dynamic).questionSetId;
    return id == null ? '' : id.toString();
  }

  String _titleOf(QuestionSet s) {
    final t = (s as dynamic).title;
    return t == null ? '' : t.toString();
  }

  // ---------------------------
  // Filtering
  // ---------------------------
  List<QuestionSet> get _filteredSets {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return widget.sets;

    return widget.sets.where((s) {
      final t = _titleOf(s).toLowerCase();
      final d = _descOf(s).toLowerCase();
      final id = _idOf(s).toLowerCase();
      return t.contains(q) || d.contains(q) || id.contains(q);
    }).toList();
  }

  void _pick(QuestionSet s) {
    setState(() => _selected = s);

    // ✅ load preview questions for the selected set
    _loadPreviewQuestions(_idOf(s));

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

    widget.onSelected?.call(s);
    Navigator.of(context).pop(s);
  }

  // ---------------------------
  // ✅ Load questions for preview + print Firestore index link (if required)
  // ---------------------------
  Future<void> _loadPreviewQuestions(String setId) async {
    final cleanId = setId.trim();

    if (cleanId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _previewQuestions = const [];
        _previewError = null;
        _previewLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _previewLoading = true;
      _previewError = null;
      _previewQuestions = const [];
    });

    // Helper: fetch questions using a specific field name
    Future<List<_PreviewQuestion>> _fetchBy({
      required String fieldName,
      required String value,
    }) async {
      final snap = await FirebaseFirestore.instance
          .collection('demographicQuestions')
          .where(fieldName, isEqualTo: value)
          .get();

      final out = <_PreviewQuestion>[];

      for (final d in snap.docs) {
        final data = d.data();

        // treat missing isDisabled as enabled
        final isDisabled = (data['isDisabled'] == true);
        if (isDisabled) continue;

        final q = _PreviewQuestion.fromMap(d.id, data);
        if (q.text.trim().isEmpty) continue;

        out.add(q);
      }

      // Sort locally (no index needed)
      out.sort((a, b) {
        final ao = a.order ?? (1 << 30);
        final bo = b.order ?? (1 << 30);
        if (ao != bo) return ao.compareTo(bo);
        return a.text.compareTo(b.text);
      });

      return out;
    }

    try {
      debugPrint('🔎 Preview: loading questions for setId="$cleanId"');

      List<_PreviewQuestion> list = await _fetchBy(
        fieldName: 'questionSetId',
        value: cleanId,
      );

      // ✅ If empty, try to resolve the SET DOC ID from demographicQuestionSets
      // This fixes cases where QuestionSet.questionSetId != doc.id but questions use doc.id
      if (list.isEmpty) {
        final setSnap = await FirebaseFirestore.instance
            .collection('demographicQuestionSets')
            .where('questionSetId', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (setSnap.docs.isNotEmpty) {
          final docId = setSnap.docs.first.id.trim();
          if (docId.isNotEmpty && docId != cleanId) {
            debugPrint(
              'ℹ️ Preview: 0 questions for "$cleanId". Retrying with set docId="$docId".',
            );
            list = await _fetchBy(fieldName: 'questionSetId', value: docId);
          }
        }
      }

      // ✅ If still empty, try common alternate field names (old data / migrations)
      if (list.isEmpty) {
        const fallbacks = <String>[
          'questionSetID',
          'setId',
          'demographicQuestionSetId',
        ];

        for (final f in fallbacks) {
          debugPrint('ℹ️ Preview: retrying using "$f" == "$cleanId"');
          final alt = await _fetchBy(fieldName: f, value: cleanId);
          if (alt.isNotEmpty) {
            list = alt;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() => _previewQuestions = list);

      if (list.isEmpty) {
        debugPrint(
          '⚠️ Preview: still 0 questions. Verify demographicQuestions has a field that matches this set id.',
        );
      } else {
        debugPrint('✅ Preview: loaded ${list.length} questions.');
      }
    } catch (e, st) {
      final msg = e.toString();

      // Print Firestore "create index" link if it ever happens
      final urlMatch = RegExp(r'(https?://[^\s\]]+)').firstMatch(msg);
      final indexUrl = urlMatch?.group(1);
      if (indexUrl != null) {
        debugPrint('🔥 Firestore index required. Create it here:\n$indexUrl');
      } else {
        debugPrint('🔥 Preview query error:\n$msg');
      }
      debugPrint('Stack:\n$st');

      if (!mounted) return;
      setState(() => _previewError = msg);
    } finally {
      if (!mounted) return;
      setState(() => _previewLoading = false);
    }
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
            // HEADER
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
                  // ✅ LEFT LIST (reduced width)
                  Expanded(
                    flex: 2, // was 3
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
                                  final isSelected = selected != null &&
                                      _idOf(selected) == _idOf(s);

                                  final desc = _descOf(s);

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
                                                  _titleOf(s),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  desc.trim().isEmpty
                                                      ? 'No description'
                                                      : desc,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
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

                  // ✅ RIGHT PREVIEW (extra width)
                  Expanded(
                    flex: 3, // was 2
                    child: Container(
                      padding: const EdgeInsets.all(14),
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

                                    // Set details card
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
                                            _titleOf(selected),
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _descOf(selected).trim().isEmpty
                                                ? 'No description provided.'
                                                : _descOf(selected),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // ✅ Questions preview
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Questions',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (_previewLoading)
                                          Text(
                                            'Loading…',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else
                                          Text(
                                            '${_previewQuestions.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    if (_previewLoading) ...[
                                      const LinearProgressIndicator(
                                          minHeight: 3),
                                      const SizedBox(height: 10),
                                    ] else if (_previewError != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          'Failed to load questions.\n$_previewError',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ] else if (_previewQuestions.isEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          'No questions found in this set.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < _previewQuestions.length;
                                                i++) ...[
                                              _questionPreviewTile(
                                                number: i + 1,
                                                text: _previewQuestions[i].text,
                                                isFollowUp: _previewQuestions[i]
                                                    .parentId
                                                    .trim()
                                                    .isNotEmpty,
                                              ),
                                              if (i !=
                                                  _previewQuestions.length - 1)
                                                const Divider(height: 16),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],

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

  Widget _questionPreviewTile({
    required int number,
    required String text,
    required bool isFollowUp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Fixed-width number column so all text lines align perfectly
        SizedBox(
          width: 40, // constant column width
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isFollowUp ? '↳ $text' : text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              height: 1.25,
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

class _PreviewQuestion {
  final String id;
  final String text;
  final int? order;
  final String parentId;

  const _PreviewQuestion({
    required this.id,
    required this.text,
    required this.order,
    required this.parentId,
  });

  factory _PreviewQuestion.fromMap(String id, Map<String, dynamic> m) {
    final rawText = (m['questionText'] ??
            m['text'] ??
            m['title'] ??
            m['question'] ??
            m['label'] ??
            '')
        .toString()
        .trim();

    int? order;
    final o = m['order'] ?? m['index'] ?? m['position'];
    if (o is int) order = o;
    if (o is num) order = o.toInt();
    if (o is String) order = int.tryParse(o);

    final parent = (m['parentQuestionId'] ?? '').toString();

    return _PreviewQuestion(
      id: id,
      text: rawText,
      order: order,
      parentId: parent,
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
  late int _maxInviteByGuest;
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
    // Initialize max invite by guest
    _maxInviteByGuest = widget.initialEvent.maxInviteByGuest;
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
      content: SizedBox(
        width: 488,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Header
              DialogStepHeader(
                icon: Icons.edit,
                title: 'Edit Event Details',
                description: 'Update the event\'s information.',
              ),
              const SizedBox(height: 24),

              // Event Name
              AppTextInputField(
                label: 'Event Name',
                controller: _nameCtrl,
              ),

              // Location (Address)
              AppTextInputField(
                label: 'Location (Address)',
                controller: _locationCtrl,
              ),

              // Service Type
              AppDropdownMenu<String>(
                label: 'Service Type',
                value: _serviceType,
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

              // Max Guests Per Invite
              AppDropdownMenu<int>(
                label: 'Max Guests Per Invite',
                helperText:
                    'Maximum number of additional guests each invitee can bring',
                value: _maxInviteByGuest,
                items: List.generate(6, (index) => index).map((number) {
                  return DropdownMenuItem<int>(
                    value: number,
                    child: Text(number == 0
                        ? 'No additional guests'
                        : number == 1
                            ? '1 additional guest'
                            : '$number additional guests'),
                  );
                }).toList(),
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() => _maxInviteByGuest = value);
                  }
                },
              ),

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
                      maxInviteByGuest: _maxInviteByGuest,
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

  double _priceOf(MenuItem item) {
    final p = item.price;
    if (p == null) return 0.0;
    if (p is num) return p.toDouble();
    return double.tryParse(p.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIds = controller.selectedMenuItemIds.toList();
      final selectedItems = controller.selectedMenuItems.toList();
      final groups = controller.menuItemGroups.toList();

      final bool hasSelection = selectedIds.isNotEmpty;
      final bool isLoadingSelectedDocs = hasSelection && selectedItems.isEmpty;

      // -----------------------------
      // Group mapping: itemId -> groupName
      // -----------------------------
      final Map<String, String> groupNameByItemId = {};
      final Set<String> groupedIds = {};
      for (final g in groups) {
        for (final id in g.itemIds) {
          final x = id.trim();
          if (x.isEmpty) continue;
          groupedIds.add(x);
          groupNameByItemId[x] = g.name;
        }
      }

      // Map for quick lookup
      final Map<String, MenuItem> itemById = {};
      for (final it in selectedItems) {
        final id = (it.menuItemId ?? '').trim();
        if (id.isNotEmpty) itemById[id] = it;
      }

      // -----------------------------
      // Estimated Total (range)
      // base = ungrouped items total
      // range add = for each group, min..max
      // -----------------------------
      double ungroupedTotal = 0.0;
      for (final it in selectedItems) {
        final id = (it.menuItemId ?? '').trim();
        if (id.isEmpty) continue;
        if (groupedIds.contains(id)) continue;
        ungroupedTotal += _priceOf(it);
      }

      double minTotal = ungroupedTotal;
      double maxTotal = ungroupedTotal;

      for (final g in groups) {
        final prices = <double>[];
        for (final id in g.itemIds) {
          final it = itemById[id];
          if (it == null) continue;
          prices.add(_priceOf(it));
        }
        if (prices.isEmpty) continue;
        prices.sort();
        minTotal += prices.first;
        maxTotal += prices.last;
      }

      final bool hasGroups = groups.isNotEmpty;
      final bool showRange = hasGroups && (minTotal != maxTotal);

      // -----------------------------
      // counts (chips)
      // -----------------------------
      final Map<String, int> typeCounts = {};
      final Map<String, int> catCounts = {};
      for (final i in selectedItems) {
        final ft = _foodTypeLabel(i).isEmpty ? 'Other' : _foodTypeLabel(i);
        final cat = _categoryLabel(i).isEmpty ? 'Other' : _categoryLabel(i);
        typeCounts[ft] = (typeCounts[ft] ?? 0) + 1;
        catCounts[cat] = (catCounts[cat] ?? 0) + 1;
      }

      // grouped count for chip
      final groupedCount = groupedIds.length;
      final org = Get.find<OrganisationController>();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _summaryChip('Total', selectedIds.length),
                  if (hasGroups) _summaryChip('Grouped', groupedCount),
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
                    itemBuilder: (_, idx) {
                      final it = selectedItems[idx];
                      final id = (it.menuItemId ?? '').trim();
                      final groupName = groupNameByItemId[id];
                      return _selectedDishRow(it, groupName: groupName);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (!org.showMenuItemPrices.value)
                  return const SizedBox.shrink();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasGroups ? 'Estimated total' : 'Total',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      showRange
                          ? '${AppCurrency.format(minTotal)} - ${AppCurrency.format(maxTotal)}'
                          : AppCurrency.format(maxTotal),
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      );
    });
  }

  Widget _selectedDishRow(MenuItem item, {String? groupName}) {
    final String ftLabel = _foodTypeLabel(item);
    final String catLabel = _categoryLabel(item);
    final bool isVeg = ftLabel.toLowerCase() == 'veg' || _isVegByCategory(item);
    final org = Get.find<OrganisationController>();

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
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                      const Text('•',
                          style: TextStyle(color: Color(0xFFCBD5E1))),
                    if (catLabel.isNotEmpty)
                      Text(
                        catLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),

                    // ✅ Group label
                    if (groupName != null && groupName.trim().isNotEmpty) ...[
                      const Text('•',
                          style: TextStyle(color: Color(0xFFCBD5E1))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Group: $groupName',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            if (!org.showMenuItemPrices.value) return const SizedBox.shrink();
            return Text(
              AppCurrency.format(p),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            );
          }),
        ],
      ),
    );
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
  /// =============================================================
  /// Category normalization (match your Cloud Function mapping)
  /// MenuItem.category is a String in your codebase.
  /// =============================================================

  String? _menuId;
  List<MenuItem> _items = [];

  // keep order (newest at top)
  final List<String> _selectedOrder = [];
  final Set<String> _selectedIds = {};
  final Map<String, MenuItem> _selectedCache = {};

  bool _loadingItems = false;
  bool _loadingSelected = false;
  bool _saving = false;

  // NEW: groups editable in dialog
  late List<MenuItemGroup> _groups;

  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  final TextEditingController _leftSearchCtrl = TextEditingController();
  final TextEditingController _rightSearchCtrl = TextEditingController();
  final OrganisationController org = Get.find<OrganisationController>();

  String _leftSearch = '';
  String _rightSearch = '';

  String? _leftCategory; // label (not key)
  String? _rightCategory; // label (not key)

  FoodType? _leftFoodType;
  FoodType? _rightFoodType;

  Size _calcDialogSize(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final w = (s.width * 0.92).clamp(980.0, 1480.0); // bigger + capped
    final h = (s.height * 0.92).clamp(720.0, 940.0); // bigger + capped
    return Size(w, h);
  }

  bool _isNarrowLayout(double dialogWidth) => dialogWidth < 1180;

  EdgeInsets get _dialogOuterPadding => const EdgeInsets.all(14);
  EdgeInsets get _bodyPadding => const EdgeInsets.fromLTRB(28, 22, 28, 26);

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

    // NEW: init groups from controller (local editable copy)
    _groups = widget.controller.menuItemGroups.toList();

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

  _PriceRange _groupPriceRange(MenuItemGroup g) {
    final prices = <double>[];
    for (final id in g.itemIds) {
      final it = _selectedCache[id];
      if (it == null) continue;
      prices.add(_priceOf(it));
    }
    if (prices.isEmpty) return const _PriceRange(0, 0);
    prices.sort();
    return _PriceRange(prices.first, prices.last);
  }

  double get _ungroupedTotal {
    final grouped = _groupedIds;
    double sum = 0.0;
    for (final it in _selectedItemsOrdered) {
      final id = (it.menuItemId ?? '').trim();
      if (id.isEmpty) continue;
      if (grouped.contains(id)) continue; // exclude grouped items
      sum += _priceOf(it);
    }
    return sum;
  }

  _PriceRange get _estimatedTotalRange {
    final base = _ungroupedTotal;

    double minTotal = base;
    double maxTotal = base;

    for (final g in _groups) {
      // group must have at least 1 cached item to contribute
      final anyLoaded = g.itemIds.any((id) => _selectedCache[id] != null);
      if (!anyLoaded) continue;

      final r = _groupPriceRange(g);
      minTotal += r.min;
      maxTotal += r.max;
    }

    return _PriceRange(minTotal, maxTotal);
  }

  bool get _hasAnyGroupsWithItems => _groups.any((g) => g.itemIds.isNotEmpty);

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
    if (!mounted) return;
    setState(() {
      _loadingItems = true;
      _items = [];
    });

    try {
      final list = await widget.controller.fetchMenuItemsForMenu(menuId);
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e, st) {
      debugPrint('Failed to load menu items: $e\n$st');
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (!mounted) return;
      setState(() => _loadingItems = false);
    }
  }

  Future<void> _persistNow() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.applyMenuSelectionAndGroups(
        newItemIds: _selectedOrder, // ALL selected ids
        groups: _groups,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _priceOf(MenuItem item) {
    final p = item.price;
    if (p == null) return 0.0;
    if (p is num) return p.toDouble();
    return double.tryParse(p.toString()) ?? 0.0;
  }

  // robust foodType
  FoodType? _foodTypeFor(MenuItem item) {
    final dynamic ft = (item as dynamic).foodType;
    if (ft is FoodType) return ft;

    if (ft is String) {
      final norm = ft.replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase();
      if (norm == 'veg') return FoodType.veg;
      if (norm == 'nonveg') return FoodType.nonVeg;
    }

    final dynamic v = (item as dynamic).isVeg;
    if (v is bool) return v ? FoodType.veg : FoodType.nonVeg;

    return null;
  }

  String _foodTypeLabelFor(MenuItem item) {
    final ft = _foodTypeFor(item);
    if (ft == FoodType.veg) return 'Veg';
    if (ft == FoodType.nonVeg) return 'Non-Veg';
    return '';
  }

  String _categoryLabelFor(MenuItem item) {
    final raw = (item.category ?? '').toString().trim();
    if (raw.isEmpty) return '';
    // If you store canonical keys already, show label from key:
    if (kMenuCategoryKeys.contains(raw)) return categoryLabelFromKey(raw);
    // Otherwise title-case
    return _titleCase(
      raw
          .replaceAll('_', ' ')
          .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
          .trim(),
    );
  }

  String _categoryKeyFor(MenuItem item) {
    final raw = (item.category ?? '').toString().trim();
    return normalizeCategoryKey(raw);
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

    // NEW: remove from any group
    _groups = _groups
        .map((g) => g.copyWith(
              itemIds: g.itemIds.where((x) => x != id).toList(),
            ))
        .where((g) => g.itemIds.isNotEmpty)
        .toList();
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

  Set<String> get _groupedIds {
    final s = <String>{};
    for (final g in _groups) {
      for (final id in g.itemIds) {
        s.add(id);
      }
    }
    return s;
  }

  /// Create/edit group dialog:
  /// - Only items from same category
  /// - Only selected items
  /// - Excludes items already in other groups (unless editing current group)
  Future<void> _showCreateOrEditGroup({
    required String categoryKey,
    MenuItemGroup? existing,
  }) async {
    final isEdit = existing != null;

    String groupName = existing?.name ?? '';
    final existingIds = (existing?.itemIds ?? const <String>[]).toSet();
    final checked = <String>{...existingIds};

    // items in this category that are selected
    final selectedSet = _selectedIds.toSet();
    final candidates = <MenuItem>[];
    for (final id in _selectedOrder) {
      final it = _selectedCache[id];
      if (it == null) continue;
      if (_categoryKeyFor(it) != categoryKey) continue;
      if (!selectedSet.contains(id)) continue;
      candidates.add(it);
    }

    // ids used by other groups (so one item cannot be in two groups)
    final usedByOtherGroups = <String>{};
    for (final g in _groups) {
      if (existing != null && g.groupId == existing.groupId) continue;
      usedByOtherGroups.addAll(g.itemIds);
    }

    // allowed ids
    final allowed = <String>{};
    for (final it in candidates) {
      final id = (it.menuItemId ?? '').trim();
      if (id.isEmpty) continue;
      if (existingIds.contains(id)) {
        allowed.add(id);
      } else if (!usedByOtherGroups.contains(id)) {
        allowed.add(id);
      }
    }

    final res = await showDialog<_GroupDialogResult?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Edit group' : 'Create group',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: groupName,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        hintText: 'e.g. Breakfast breads',
                      ),
                      onChanged: (v) => groupName = v,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select items (only from this category)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ IMPORTANT: shrinkWrap MUST be false here to prevent huge overflow
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: false,
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final it = candidates[i];
                          final id = (it.menuItemId ?? '').trim();
                          final disabled = !allowed.contains(id);
                          final isOn = checked.contains(id);

                          return CheckboxListTile(
                            value: isOn,
                            onChanged: disabled
                                ? null
                                : (v) {
                                    setLocal(() {
                                      if (v == true) {
                                        checked.add(id);
                                      } else {
                                        checked.remove(id);
                                      }
                                    });
                                  },
                            title: Text(
                              it.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: disabled && !existingIds.contains(id)
                                ? Text(
                                    'Already used in another group',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                  )
                                : Text(
                                    [
                                      _foodTypeLabelFor(it),
                                      categoryLabelFromKey(categoryKey),
                                    ].where((e) => e.isNotEmpty).join(' • '),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    final name = groupName.trim();
                    if (name.isEmpty) return;
                    if (checked.length < 2) return;

                    Navigator.of(ctx)
                        .pop(_GroupDialogResult(name, checked.toList()));
                  },
                  child: Text(
                    isEdit ? 'Save' : 'Create',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (res == null) return;
    if (!mounted) return;

    // ✅ Safer: schedule the setState after the dialog has fully closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        final pickedSet = res.itemIds.toSet();

        // remove picked from other groups
        _groups = _groups
            .map((g) {
              if (existing != null && g.groupId == existing.groupId) return g;
              return g.copyWith(
                itemIds:
                    g.itemIds.where((id) => !pickedSet.contains(id)).toList(),
              );
            })
            .where((g) => g.itemIds.isNotEmpty)
            .toList();

        if (isEdit) {
          _groups = _groups.map((g) {
            if (g.groupId != existing!.groupId) return g;
            return g.copyWith(name: res.name, itemIds: res.itemIds);
          }).toList();
        } else {
          final gid = 'grp_${DateTime.now().microsecondsSinceEpoch}';
          _groups.add(MenuItemGroup(
            groupId: gid,
            name: res.name,
            categoryKey: categoryKey,
            maxPick: 1,
            itemIds: res.itemIds,
          ));
        }
      });

      _persistNow();
    });
  }

  void _deleteGroup(String groupId) {
    setState(() {
      _groups = _groups.where((g) => g.groupId != groupId).toList();
    });
    _persistNow();
  }

  void _removeItemFromGroup(String groupId, String itemId) {
    setState(() {
      _groups = _groups
          .map((g) => g.groupId == groupId
              ? g.copyWith(
                  itemIds: g.itemIds.where((x) => x != itemId).toList(),
                )
              : g)
          .where((g) => g.itemIds.isNotEmpty)
          .toList();
    });
  }

  Widget _buildLeftItemRow(MenuItem item) {
    final id = (item.menuItemId ?? '').trim();
    final bool isSelected = id.isNotEmpty && _selectedIds.contains(id);

    final bool isVeg = _foodTypeFor(item) == FoodType.veg;
    final ftLabel = _foodTypeLabelFor(item);
    final catLabel = _categoryLabelFor(item);

    final price = _priceOf(item);

    final bg = isSelected
        ? (isVeg ? Colors.green.shade50 : Colors.red.shade50)
        : Colors.white;

    final border = isSelected
        ? (isVeg ? Colors.green.shade700 : Colors.red.shade700)
        : Colors.grey.shade300;

    final org = Get.find<OrganisationController>();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _toggleSelection(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            _foodSquareIcon(isVeg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (ftLabel.isNotEmpty) ftLabel,
                      if (catLabel.isNotEmpty) catLabel,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              if (!org.showMenuItemPrices.value) return const SizedBox.shrink();
              return Text(
                AppCurrency.format(price),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 13),
              );
            }),
            const SizedBox(width: 10),
            SizedBox(
              height: 34,
              child: TextButton(
                onPressed: () => _toggleSelection(item),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? Colors.black : Colors.white,
                  foregroundColor: isSelected ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  isSelected ? 'Remove' : 'Add',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, List<MenuModel> menus, double dialogWidth) {
    final dropdownWidth = (dialogWidth * 0.42).clamp(380.0, 560.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select menu & dishes',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: dropdownWidth,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Menu (browse)',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _menuId,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  iconEnabledColor: Colors.white,
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

  Widget _buildLeftPanel(List<MenuItem> filteredLeft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Before selection',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
        const SizedBox(height: 12),

        // ✅ LEFT FILTERS (keep your existing filter UI here if you want)
        // If you already render search/category/pills in main build, skip.

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E9EE)),
            ),
            child: _loadingItems
                ? const Center(child: CircularProgressIndicator())
                : (filteredLeft.isEmpty
                    ? Center(
                        child: Text(
                          'No items match your filters',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : Scrollbar(
                        controller: _leftScrollController,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: _leftScrollController,
                          primary: false, // ✅ important
                          itemCount: filteredLeft.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, idx) =>
                              _buildLeftItemRow(filteredLeft[idx]),
                        ),
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    // Build selected list ids filtered by RIGHT filters
    final bool rightFiltersActive = _rightSearch.trim().isNotEmpty ||
        _rightCategory != null ||
        _rightFoodType != null;

    bool match(MenuItem it) {
      final q = _rightSearch.toLowerCase().trim();
      final nameOk = q.isEmpty || it.name.toLowerCase().contains(q);

      final catLabel = _categoryLabelFor(it);
      final catOk = _rightCategory == null || _rightCategory == catLabel;

      final ft = _foodTypeFor(it);
      final ftOk = _rightFoodType == null || ft == _rightFoodType;

      return nameOk && catOk && ftOk;
    }

    final visibleSelectedIds = <String>[];
    for (final id in _selectedOrder) {
      final it = _selectedCache[id];
      if (it == null) {
        // show loading cards only when no right filters are applied
        if (!rightFiltersActive) visibleSelectedIds.add(id);
        continue;
      }
      if (match(it)) visibleSelectedIds.add(id);
    }

    final visibleSet = visibleSelectedIds.toSet();
    final visibleItems = visibleSelectedIds
        .map((id) => _selectedCache[id])
        .whereType<MenuItem>()
        .toList();

    final vegCount =
        visibleItems.where((it) => _foodTypeFor(it) == FoodType.veg).length;
    final nonCount =
        visibleItems.where((it) => _foodTypeFor(it) == FoodType.nonVeg).length;

    // category counts for RIGHT dropdown (from all selected, not filtered)
    final Map<String, int> rightCatCounts = {};
    for (final it in _selectedItemsOrdered) {
      final cat =
          _categoryLabelFor(it).isEmpty ? 'Other' : _categoryLabelFor(it);
      rightCatCounts[cat] = (rightCatCounts[cat] ?? 0) + 1;
    }
    final rightCats = rightCatCounts.keys.toList()..sort();

    // groups by categoryKey
    final Map<String, List<MenuItemGroup>> groupsByCat = {};
    for (final g in _groups) {
      groupsByCat.putIfAbsent(g.categoryKey, () => []).add(g);
    }

    // categories present in visible selected items
    final Set<String> visibleCategoryKeys = {};
    for (final id in visibleSelectedIds) {
      final it = _selectedCache[id];
      if (it == null) continue;
      visibleCategoryKeys.add(_categoryKeyFor(it));
    }
    // include categories where groups exist (even if filtered hides all items)
    visibleCategoryKeys.addAll(groupsByCat.keys);

    final catKeysSorted = visibleCategoryKeys.toList()
      ..sort(
          (a, b) => categoryLabelFromKey(a).compareTo(categoryLabelFromKey(b)));

    final groupedIds = _groupedIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + counts
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected items • ${_selectedOrder.length}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _infoChip('Veg • $vegCount', highlight: true),
            const SizedBox(width: 8),
            _infoChip('Non-Veg • $nonCount', negative: true),
          ],
        ),
        const SizedBox(height: 12),

        // RIGHT search
        TextField(
          controller: _rightSearchCtrl,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search within selected items',
            hintStyle: GoogleFonts.poppins(),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (v) => setState(() => _rightSearch = v),
        ),
        const SizedBox(height: 10),

        // RIGHT filters row
        Row(
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                value: _rightCategory,
                hint: Text('Category', style: GoogleFonts.poppins()),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All (${_selectedOrder.length})',
                        style: GoogleFonts.poppins()),
                  ),
                  ...rightCats.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c,
                      child: Text('$c (${rightCatCounts[c] ?? 0})',
                          style: GoogleFonts.poppins()),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _rightCategory = v),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _filterPill(
              'Veg',
              _rightFoodType == FoodType.veg,
              () => setState(() => _rightFoodType =
                  _rightFoodType == FoodType.veg ? null : FoodType.veg),
            ),
            const SizedBox(width: 8),
            _filterPill(
              'Non-Veg',
              _rightFoodType == FoodType.nonVeg,
              () => setState(() => _rightFoodType =
                  _rightFoodType == FoodType.nonVeg ? null : FoodType.nonVeg),
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
                  style: GoogleFonts.poppins(color: Colors.black)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // RIGHT list container
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _loadingSelected
                ? const Center(child: CircularProgressIndicator())
                : (visibleSelectedIds.isEmpty
                    ? Center(
                        child: Text(
                          'No selected items match your filters',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : Scrollbar(
                        controller: _rightScrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: _rightScrollController,
                          primary: false, // ✅ important
                          children: [
                            for (final catKey in catKeysSorted) ...[
                              _categorySection(
                                categoryKey: catKey,
                                visibleSelectedIds: visibleSelectedIds,
                                visibleSet: visibleSet,
                                groupedIds: groupedIds,
                                groupsInThisCat:
                                    groupsByCat[catKey] ?? const [],
                              ),
                              const SizedBox(height: 12),
                            ],

                            // placeholders for ids not yet fetched (only when no right filters)
                            if (!rightFiltersActive) ...[
                              ...visibleSelectedIds
                                  .where((id) => _selectedCache[id] == null)
                                  .map((id) => _loadingRow(id)),
                            ],
                          ],
                        ),
                      )),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final menus = widget.controller.availableMenus;
    final dialogSize = _calcDialogSize(context);
    final isNarrow = _isNarrowLayout(dialogSize.width);

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

    // precompute estimated total range for bottom bar
    final range = _estimatedTotalRange;
    final showRange = _hasAnyGroupsWithItems && (range.min != range.max);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.05), // slightly calmer
      ),
      child: Dialog(
        insetPadding: _dialogOuterPadding,
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogSize.width,
              maxHeight: dialogSize.height,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    // HEADER (sticky)
                    _buildHeader(context, menus, dialogSize.width),

                    // BODY
                    Expanded(
                      child: Padding(
                        padding: _bodyPadding,
                        child: isNarrow
                            ? Column(
                                children: [
                                  // LEFT block
                                  Expanded(
                                    child: _buildLeftPanel(filteredLeft),
                                  ),
                                  const SizedBox(height: 18),
                                  // RIGHT block
                                  Expanded(
                                    child: _buildRightPanel(),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _buildLeftPanel(filteredLeft)),
                                  const SizedBox(width: 22),
                                  Container(
                                      width: 1, color: const Color(0xFFE5E7EB)),
                                  const SizedBox(width: 22),
                                  Expanded(child: _buildRightPanel()),
                                ],
                              ),
                      ),
                    ),

                    // FOOTER (sticky)
                    Container(
                      padding: const EdgeInsets.fromLTRB(26, 14, 26, 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Items pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                Text('Items:',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Text(
                                    '${_selectedOrder.length}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Total pill (range aware)
                          Obx(() {
                            if (!org.showMenuItemPrices.value)
                              return const SizedBox.shrink();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _hasAnyGroupsWithItems
                                        ? 'Estimated Total'
                                        : 'Total',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    showRange
                                        ? '${AppCurrency.format(range.min)} - ${AppCurrency.format(range.max)}'
                                        : AppCurrency.format(range.max),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const Spacer(),

                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    setState(() => _saving = true);
                                    try {
                                      widget.controller.lastBrowsedMenuId
                                          .value = _menuId;
                                      await widget.controller
                                          .applyMenuSelectionAndGroups(
                                        newItemIds: _selectedOrder,
                                        groups: _groups,
                                      );
                                      if (mounted) Navigator.of(context).pop();
                                    } finally {
                                      if (mounted)
                                        setState(() => _saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Confirm',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categorySection({
    required String categoryKey,
    required List<String> visibleSelectedIds,
    required Set<String> visibleSet,
    required Set<String> groupedIds,
    required List<MenuItemGroup> groupsInThisCat,
  }) {
    // Visible ungrouped items for this category
    final ungroupedVisible = <MenuItem>[];
    for (final id in visibleSelectedIds) {
      final it = _selectedCache[id];
      if (it == null) continue;
      if (_categoryKeyFor(it) != categoryKey) continue;
      if (groupedIds.contains(id)) continue;
      ungroupedVisible.add(it);
    }

    // Visible groups for this category
    final visibleGroups = <MenuItemGroup>[];
    for (final g in groupsInThisCat) {
      final anyVisible = g.itemIds.any((id) => visibleSet.contains(id));
      if (anyVisible) visibleGroups.add(g);
    }

    final showSection = ungroupedVisible.isNotEmpty || visibleGroups.isNotEmpty;
    if (!showSection) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // category header + create group
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryLabelFromKey(categoryKey),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _showCreateOrEditGroup(categoryKey: categoryKey),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Create group', style: GoogleFonts.poppins()),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // groups (expansion tiles)
          for (final g in visibleGroups) ...[
            Builder(builder: (_) {
              final r = _groupPriceRange(g);

              // if prices are not loaded yet, don't show range
              final hasAnyPriceLoaded =
                  g.itemIds.any((id) => _selectedCache[id] != null);

              final showPrices = org.showMenuItemPrices.value;

              final subtitleText = (!showPrices || !hasAnyPriceLoaded)
                  ? 'Guest can pick ${g.maxPick} item'
                  : (r.min == r.max
                      ? 'Guest can pick ${g.maxPick} item • ${AppCurrency.format(r.min)}'
                      : 'Guest can pick ${g.maxPick} item • ${AppCurrency.format(r.min)} - ${AppCurrency.format(r.max)}');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: Text(
                    '${g.name}  •  ${g.itemIds.length} items',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Obx(() {
                    final showPrices = org.showMenuItemPrices.value;
                    final txt = (!showPrices || !hasAnyPriceLoaded)
                        ? 'Guest can pick ${g.maxPick} item'
                        : (r.min == r.max
                            ? 'Guest can pick ${g.maxPick} item • ${AppCurrency.format(r.min)}'
                            : 'Guest can pick ${g.maxPick} item • ${AppCurrency.format(r.min)} - ${AppCurrency.format(r.max)}');

                    return Text(
                      txt,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade700),
                    );
                  }),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit group',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showCreateOrEditGroup(
                          categoryKey: categoryKey,
                          existing: g,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete group',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _deleteGroup(g.groupId),
                      ),
                    ],
                  ),
                  children: [
                    for (final id in g.itemIds) ...[
                      if (!visibleSet.contains(id))
                        const SizedBox.shrink()
                      else ...[
                        _groupItemRow(groupId: g.groupId, itemId: id),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              );
            }),
          ],

          // ungrouped items in this category
          if (ungroupedVisible.isNotEmpty) ...[
            Text(
              'Ungrouped',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            for (final it in ungroupedVisible) ...[
              _selectedItemRow(it),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _selectedItemRow(MenuItem it) {
    final id = (it.menuItemId ?? '').trim();
    final price = _priceOf(it);
    final isVeg = _foodTypeFor(it) == FoodType.veg;
    final ftLabel = _foodTypeLabelFor(it);
    final cat = _categoryLabelFor(it);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                Text(it.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  [if (ftLabel.isNotEmpty) ftLabel, if (cat.isNotEmpty) cat]
                      .join(' • '),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!org.showMenuItemPrices.value) return const SizedBox.shrink();
            return Text(
              AppCurrency.format(price),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            );
          }),
          IconButton(
            tooltip: 'Remove from selection',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _removeId(id)),
          ),
        ],
      ),
    );
  }

  Widget _groupItemRow({required String groupId, required String itemId}) {
    final it = _selectedCache[itemId];
    if (it == null) return _loadingRow(itemId);

    final price = _priceOf(it);
    final isVeg = _foodTypeFor(it) == FoodType.veg;
    final ftLabel = _foodTypeLabelFor(it);
    final cat = _categoryLabelFor(it);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
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
                Text(it.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  [if (ftLabel.isNotEmpty) ftLabel, if (cat.isNotEmpty) cat]
                      .join(' • '),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!org.showMenuItemPrices.value) return const SizedBox.shrink();
            return Text(
              AppCurrency.format(price),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            );
          }),
          IconButton(
            tooltip: 'Remove from group (keep selected)',
            icon: const Icon(Icons.link_off, size: 18),
            onPressed: () => _removeItemFromGroup(groupId, itemId),
          ),
          IconButton(
            tooltip: 'Remove from selection',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _removeId(itemId)),
          ),
        ],
      ),
    );
  }

  Widget _loadingRow(String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading item...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _removeId(id)),
          ),
        ],
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
              color: Colors.black.withValues(alpha: 0.02),
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

class EventAnalyzerCard extends StatefulWidget {
  final String eventId;
  const EventAnalyzerCard({super.key, required this.eventId});

  @override
  State<EventAnalyzerCard> createState() => _EventAnalyzerCardState();
}

class _EventAnalyzerCardState extends State<EventAnalyzerCard> {
  late final CloudFunctionsService _svc;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  DateTime? _loadedAt;

  bool _showAllMenu = false;

  @override
  void initState() {
    super.initState();
    _svc = Get.find<CloudFunctionsService>();
    _load();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, int> _asStringIntMap(dynamic v) {
    if (v is Map) {
      final out = <String, int>{};
      v.forEach((k, val) {
        final key = (k ?? '').toString();
        out[key] = _toInt(val);
      });
      return out;
    }
    return <String, int>{};
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _svc.getEventAnalytics(eventId: widget.eventId);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loadedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _asMap(_data?['invitations']);
    final demo = _asMap(_data?['demographics']);
    final menu = _asMap(_data?['menu']);

    final totalInv = _toInt(inv['total']);
    final sent = _toInt(inv['sent']);
    final demoDone = _toInt(inv['demographicsSubmitted']);
    final menuDone = _toInt(inv['menuSubmitted']);

    final demoResponses = _toInt(demo['responses']);
    final menuResponses = _toInt(menu['responses']);

    final lastUpdated = _loadedAt == null
        ? null
        : DateFormat('dd MMM, HH:mm').format(_loadedAt!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event analyzer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Updated • $lastUpdated',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh analytics',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_loading) ...[
            Text(
              'Loading analytics...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
          ] else if (_error != null) ...[
            Text(
              'Failed to load analytics',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text('Try again', style: GoogleFonts.poppins()),
              ),
            ),
          ] else ...[
            // 1) Completion funnel (UNCHANGED)
            Text(
              'Completion funnel',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statTile('Invited', totalInv, totalInv),
                _statTile('Emails sent', sent, totalInv),
                _statTile('Demographics done', demoDone, totalInv),
                _statTile('Menu done', menuDone, totalInv),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),

            // 2) Navigation to dedicated analyzer pages
            Text(
              'Analyze responses',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 920;

                final demoCard = _analyzerNavCard(
                  title: 'Demographic analyzer',
                  subtitle: demoResponses == 0
                      ? 'No responses yet'
                      : '$demoResponses responses',
                  icon: Icons.assignment_outlined,
                  onTap: () {
                    context.push(
                      '/event-details/${widget.eventId}/demographic-analyzer',
                    );
                  },
                );

                final menuCard = _analyzerNavCard(
                  title: 'Menu items analyzer',
                  subtitle: menuResponses == 0
                      ? 'No selections yet'
                      : '$menuResponses responses',
                  icon: Icons.restaurant_menu,
                  onTap: () {
                    context.push(
                      '/event-details/${widget.eventId}/menu-analyzer',
                    );
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      demoCard,
                      const SizedBox(height: 12),
                      menuCard,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: demoCard),
                    const SizedBox(width: 14),
                    Expanded(child: menuCard),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _analyzerNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF111827)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'View',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, int value, int total) {
    final pct = (total <= 0) ? 0 : (value / total);
    final pctText = total <= 0 ? '—' : '${(pct * 100).round()}%';

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$value',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                pctText,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniBar(value: value, total: total <= 0 ? 1 : total),
        ],
      ),
    );
  }

  Widget _miniBar({required int value, required int total}) {
    final p = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: const Color(0xFFE5E7EB),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: p,
            child: Container(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _GroupDialogResult {
  final String name;
  final List<String> itemIds;
  const _GroupDialogResult(this.name, this.itemIds);
}

class _PriceRange {
  final double min;
  final double max;
  const _PriceRange(this.min, this.max);
}
