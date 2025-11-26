import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_body.dart';
import 'package:traxx_wepapp/widgets/event_details_header.dart';

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
          materialGapSize: 12,
          expandedHeaderPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          expansionCallback: (panelIndex, isExpanded) {
            setState(() {
              _expandedPanels[panelIndex] = !isExpanded;
            });
          },
          children: [
            //Menu Panel
            ExpansionPanel(
              backgroundColor: AppColors.white,
              isExpanded: _expandedPanels[0],
              headerBuilder: (context, isExpanded) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _expandedPanels[0] = !_expandedPanels[0];
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
                        AppText.styledHeadingMedium(
                          context,
                          'Menu',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              body: MenuPanelBody(
                mainController: controller,
              ),
            ),
            ExpansionPanel(
              backgroundColor: AppColors.white,
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
                        AppText.styledHeadingMedium(
                          context,
                          'Guest List',
                          color: AppColors.primary,
                        ),
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
