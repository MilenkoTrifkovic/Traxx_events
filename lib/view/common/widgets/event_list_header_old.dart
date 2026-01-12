import 'package:flutter/material.dart';
import 'package:traxx_wepapp/view/common/widgets/sort_events_old.dart';

class EventListHeader extends StatelessWidget {
  const EventListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Row(
          children: [
            // Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
            // Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold)),
            // Text('Draft', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        )),
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SortEvents(),
          ],
        )),
      ],
    );
  }
}
