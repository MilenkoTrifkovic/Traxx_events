import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_body.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.event == null) {
      return const Center(
        child: Text('Event not found.',
            style: TextStyle(fontSize: 16, color: Color(0xFF374151))),
      );
    }
    final event = controller.event!;
    final organisation = controller.organisation!;
    final venue = controller.venue!;
    final dateStr =
        "${event.date.day.toString().padLeft(2, '0')}.${event.date.month.toString().padLeft(2, '0')}.${event.date.year}";
    final timeStr =
        "${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}";

    return SingleChildScrollView(
      child: Column(
        children: [
          EventDetailsHeader(
            title: event.name,
            status: event.status,
            date: dateStr,
            time: timeStr,
            location: organisation.city,
            serviceType: event.serviceType,
            venue: venue.name,
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

              // 2. Guest List Panel
              ExpansionPanel(
                backgroundColor: AppColors.white,
                isExpanded: _expandedPanels[1],
                headerBuilder: (context, isExpanded) {
                  return _buildPanelHeader(context, 'Guest List', 1);
                },
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Guest list panel content goes here.'),
                ),
              ),

              // 3. Demographic Questions Panel (NEW)
              ExpansionPanel(
                backgroundColor: AppColors.white,
                isExpanded: _expandedPanels[2],
                headerBuilder: (context, isExpanded) {
                  return _buildPanelHeader(context, 'Demographic Questions', 2);
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

      // SCENARIO: No Questions Created
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
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Demographic Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        );
      }

      // SCENARIO: Questions Exist -> Show List with "Add New" Button
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 HEADER ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.styledBodyMedium(context, "Available Question Sets:",
                    color: Colors.grey.shade700, weight: FontWeight.w600),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to Question Sets list to create/manage
                    context.push(AppRoute.hostQuestionSets.path);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        AppColors.primary, // Use your primary color
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔹 LIST OF SETS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final set = questions[index];
                return Card(
                  elevation: 0,
                  color: const Color(0xFFF9FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      set.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      set.description.isNotEmpty
                          ? set.description
                          : 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                    onTap: () {
                      // Navigate to specific questions in this set
                      final uri = Uri(
                        path: AppRoute.hostQuestions.path,
                        queryParameters: {
                          'setId': set.questionSetId,
                          'setTitle': set.title,
                          'setDescription': set.description,
                        },
                      ).toString();

                      context.push(uri);
                    },
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
