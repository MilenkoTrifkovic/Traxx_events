import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';
import 'widgets/menu_expansion_panel_widget.dart';

class AdminEventDetails extends StatefulWidget {
  final String eventId;
  const AdminEventDetails({super.key, required this.eventId});

  @override
  State<AdminEventDetails> createState() => _AdminEventDetailsState();
}

class _AdminEventDetailsState extends State<AdminEventDetails> {
  final List<bool> _expandedPanels = [false, false];
  late final AdminEventDetailsController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = AdminEventDetailsController();
    controller.loadEvent(widget.eventId).then((_) {
      setState(() {
        isLoading = false;
      });
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
    return Column(
      children: [
        EventDetailsHeader(
          title: event.name,
          status: event.status,
          date: dateStr,
          time: timeStr,
          location: organisation.city,
          venue: venue.name,
        ),
        ExpansionPanelList(
          expansionCallback: (panelIndex, isExpanded) {
            setState(() {
              _expandedPanels[panelIndex] = !isExpanded;
            });
          },
          children: [
            //Menu Panel
            MenuExpansionPanelWidget.buildPanel(
              isExpanded: _expandedPanels[0],
              onHeaderTap: () {
                setState(() {
                  _expandedPanels[0] = !_expandedPanels[0];
                });
              },
              context: context,
            ),
            ExpansionPanel(
              isExpanded: _expandedPanels[1],
              headerBuilder: (context, isExpanded) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _expandedPanels[1] = !_expandedPanels[1];
                    });
                  },
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Text('Guest List',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Guest list panel content goes here.'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
