import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/panel_body.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/panel_header.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_body.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';

// ---------- AdminEventDetails widget (updated) ----------
class AdminEventDetails extends StatefulWidget {
  final String eventId;
  const AdminEventDetails({super.key, required this.eventId});

  @override
  State<AdminEventDetails> createState() => _AdminEventDetailsState();
}

class _AdminEventDetailsState extends State<AdminEventDetails> {
  // Now managing 3 panels: Menu, Guest List, Demographic Questions
  final List<bool> _expandedPanels = [false, false, false];
  late final AdminEventDetailsController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Guest logic (from Milenko)
    Get.put(AdminGuestListController());

    controller = AdminEventDetailsController();
    controller.loadEvent(widget.eventId).then((_) {
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

    // Clean up guest controller (from Milenko)
    Get.delete<AdminGuestListController>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Reactive rebuild based on controller.event etc.
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
          "${evt.date.hour.toString().padLeft(2, '0')}:${evt.date.minute.toString().padLeft(2, '0')}";

      return SingleChildScrollView(
        child: Column(
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
            ExpansionPanelList(
              materialGapSize: 12,
              expandedHeaderPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              expansionCallback: (panelIndex, isExpanded) {
                setState(() {
                  _expandedPanels[panelIndex] = !isExpanded;
                });
              },
              children: [
                // 1. Menu Panel
                ExpansionPanel(
                  backgroundColor: AppColors.white,
                  isExpanded: _expandedPanels[0],
                  headerBuilder: (context, isExpanded) {
                    return _buildPanelHeader(context, 'Menu', 0);
                  },
                  body: MenuPanelBody(
                    mainController: controller,
                  ),
                ),

                // 2. Guest List Panel (real guest logic integrated)
                ExpansionPanel(
                  backgroundColor: AppColors.white,
                  isExpanded: _expandedPanels[1],
                  headerBuilder: (context, isExpanded) {
                    return GuestPanelHeader(
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _expandedPanels[1] = !_expandedPanels[1];
                        });
                      },
                    );
                  },
                  body: GuestPanelBody(),
                ),

                // 3. Demographic Questions Panel
                ExpansionPanel(
                  backgroundColor: AppColors.white,
                  isExpanded: _expandedPanels[2],
                  headerBuilder: (context, isExpanded) {
                    return _buildPanelHeader(
                      context,
                      'Demographic Questions',
                      2,
                    );
                  },
                  body: DemographicQuestionsPanelBody(
                    controller: controller,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      );
    });
  }

  // Helper widget for panel headers to avoid code duplication
  Widget _buildPanelHeader(BuildContext context, String title, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _expandedPanels[index] = !_expandedPanels[index];
        });
      },
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            AppText.styledHeadingMedium(
              context,
              title,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
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
                    onPressed: () => controller.openDemographicPicker(),
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
                onPressed: () => controller.openDemographicPicker(),
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
                        set.description?.isNotEmpty == true
                            ? set.description!
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
  final Function(QuestionSet) onSelected;

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
    return AlertDialog(
      title: const Text("Select Demographic Question Set"),
      content: SizedBox(
        width: 500,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.sets.length,
          itemBuilder: (_, i) {
            final set = widget.sets[i];
            final isSel = selected?.questionSetId == set.questionSetId;

            return ListTile(
              title: Text(set.title),
              subtitle: Text(set.description ?? ''),
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
          onPressed: () => Get.back(),
        ),
        ElevatedButton(
          onPressed: selected == null
              ? null
              : () {
                  widget.onSelected(selected!);
                  Get.back();
                },
          child: const Text("Choose"),
        )
      ],
    );
  }
}
