import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Card displaying event information
class EventInfoCard extends StatelessWidget {
  final Event event;

  const EventInfoCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event,
                    color: AppColors.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                AppText.styledHeadingSmall(
                  context,
                  'Event Information',
                  weight: FontWeight.w600,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context, 
              Icons.celebration, 
              'Event Name', 
              event.name,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Date',
              _formatDate(event.date),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Time',
              _formatTime(event.startTime, event.endTime),
            ),
            if (event.address.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.location_on,
                'Location',
                event.address,
              ),
            ],
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.info_outline,
                'Description',
                event.description!,
              ),
            ],
            if (event.dressCode != null && event.dressCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.checkroom,
                'Dress Code',
                event.dressCode!,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.event_available,
              'RSVP Deadline',
              _formatDate(event.rsvpDeadline),
            ),
            if (event.specialNotes != null && event.specialNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.notes,
                'Special Notes',
                event.specialNotes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = days[(date.weekday - 1) % 7];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay start, TimeOfDay end) {
    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
    
    return '${formatTimeOfDay(start)} - ${formatTimeOfDay(end)}';
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryAccent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledLabelMedium(
                context,
                label,
                weight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              AppText.styledBodyMedium(
                context,
                value,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
