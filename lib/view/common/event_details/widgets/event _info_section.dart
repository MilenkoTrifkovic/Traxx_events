import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';

class EventInfoSection extends StatelessWidget {
  final Event event;
  const EventInfoSection({super.key, required this.event});

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  Widget _buildInfoItem(BuildContext context, double width, IconData icon,
      String label, String value) {
    return Padding(
      padding: AppPadding.vertical(context, paddingType: Sizes.sm),
      child: SizedBox(
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            AppSpacing.horizontalXs(context),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.styledBodyLarge(context, label,
                    weight: FontWeight.bold,
                    color: AppColors.onBackground(context)),
                const SizedBox(height: 4),
                AppText.styledBodyMedium(context, value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 1000 ? 3 : (maxWidth >= 600 ? 2 : 1);
        final double spacing = AppSpacing.sm(context);
        final double itemWidth = (maxWidth - (columns - 1) * spacing) / columns;
        List<Widget> infoWidgets = [
          _buildInfoItem(
            context,
            itemWidth,
            Icons.calendar_today,
            'Date & Time',
            'Start: ${_formatDate(event.startDateTime)} - ${_formatTime(event.startDateTime)}\n'
                'End:   ${_formatDate(event.endDateTime)} - ${_formatTime(event.endDateTime)}',
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.location_on,
            'Address',
            event.address,
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.people,
            'Capacity',
            '${event.capacity} people',
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.access_time,
            'RSVP Deadline',
            _formatDateTime(event.rsvpDeadline),
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.category,
            'Event Type',
            event.eventType,
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.category,
            'Service Type',
            event.serviceType.name.capitalizeString(),
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.room_service,
            'Service Type',
            event.serviceType.name.capitalizeString(),
          ),
          _buildInfoItem(
            context,
            itemWidth,
            Icons.schedule,
            'Timezone',
            event.timezone,
          ),
          if (event.dressCode != null && event.dressCode!.isNotEmpty)
            _buildInfoItem(
              context,
              itemWidth,
              Icons.checkroom,
              'Dress Code',
              event.dressCode!,
            ),
          if (event.plannerEmail != null && event.plannerEmail!.isNotEmpty)
            _buildInfoItem(
              context,
              itemWidth,
              Icons.email,
              'Planner Email',
              event.plannerEmail!,
            ),
          if (event.specialNotes != null && event.specialNotes!.isNotEmpty)
            _buildInfoItem(
              context,
              itemWidth,
              Icons.note,
              'Special Notes',
              event.specialNotes!,
            ),
        ];
        return Wrap(
          alignment: WrapAlignment.start,
          spacing: spacing,
          children: infoWidgets,
        );
      },
    );
  }
}
