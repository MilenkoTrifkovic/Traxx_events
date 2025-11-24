import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class EventStatusWidget extends StatelessWidget {
  final EventStatus status;
  const EventStatusWidget({super.key, required this.status});

  Color get backgroundColor {
    switch (status) {
      case EventStatus.draft:
        return const Color(0xFFF3F4F6); // light gray
      case EventStatus.live:
        return const Color(0xFFE0F7FA); // light blue
      case EventStatus.upcoming:
        return const Color(0xFFE0F2FE); // light cyan
      case EventStatus.completed:
        return const Color(0xFFF1F8E9); // light green
    }
  }

  Color get textColor {
    switch (status) {
      case EventStatus.draft:
        return const Color(0xFF6B7280); // gray
      case EventStatus.live:
        return const Color(0xFF2563EB); // blue
      case EventStatus.upcoming:
        return const Color(0xFF0891B2); // cyan
      case EventStatus.completed:
        return const Color(0xFF4CAF50); // green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText.styledMetaSmall(
        context,
        status.displayName,
        color: textColor,
        weight: FontWeight.w600,
      ),
    );
  }
}
