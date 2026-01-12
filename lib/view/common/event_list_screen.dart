import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/common/widgets/event_filter_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_list_header_old.dart';
import 'package:traxx_wepapp/view/common/widgets/list_of_events.dart';

/// A screen that displays a list of events for the host user.
///
/// This screen includes:
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
/// - The behavior of the list items depends on the logged in user type (host/guest).
class EventListScreen extends StatelessWidget {
  EventListScreen({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Event list container
          Obx(() => Container(
              decoration: BoxDecoration(
                color: eventListController.events.isNotEmpty
                    ? AppColors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.sm),
                child: Column(
                  children: [
                    // Show header and filters if there are any events in the system
                    if (eventListController.events.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Event'),
                          onPressed: () async {
                            final selectedEventId = await showDialog<String?>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => CopyEventDialog(
                                events: eventListController.events.toList(),
                              ),
                            );

                            if (selectedEventId == null) return;

                            await eventListController
                                .copyEventById(selectedEventId);
                          },
                        ),
                      ),
                      AppSpacing.verticalXs(context),

                      // Existing
                      EventFilterSection(),
                      AppSpacing.verticalXs(context),
                    ],

                    const ListOfEvents(),
                  ],
                ),
              ))),
        ],
      ),
    );
  }
}

class CopyEventDialog extends StatefulWidget {
  final List<Event> events;
  const CopyEventDialog({super.key, required this.events});

  @override
  State<CopyEventDialog> createState() => _CopyEventDialogState();
}

class _CopyEventDialogState extends State<CopyEventDialog> {
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copy Event'),
      content: SizedBox(
        width: 520,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.events.length,
          itemBuilder: (context, index) {
            final e = widget.events[index];

            return CheckboxListTile(
              value: _selectedEventId == e.eventId,
              title: Text(e.name),
              subtitle: Text('Status: ${e.status.name}'),
              onChanged: (checked) {
                setState(() {
                  _selectedEventId = checked == true ? e.eventId : null;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedEventId == null
              ? null
              : () => Navigator.pop(context, _selectedEventId),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
