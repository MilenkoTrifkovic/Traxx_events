import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/widgets/event_status_widget.dart';

class EventDetailsHeader extends StatelessWidget {
  final String title;
  final EventStatus status;
  final String date;
  final String time;
  final String location;
  final String venue;

  const EventDetailsHeader({
    super.key,
    required this.title,
    required this.status,
    required this.date,
    required this.time,
    required this.location,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.wine_bar,
                          color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    AppText.styledHeadingLarge(
                      context,
                      title,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    EventStatusWidget(
                      status: status,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    AppText.styledBodyMedium(context, date,
                        color: AppColors.secondary),
                    const SizedBox(width: 8),
                    AppText.styledBodyMedium(context, time,
                        color: AppColors.secondary),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on,
                        size: 18, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    AppText.styledBodyMedium(context, location,
                        color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    AppText.styledBodyMedium(context, venue,
                        color: AppColors.secondary),
                  ],
                ),
              ],
            ),
          ),
          // Right section: 4 placeholders for avatars/images
          Row(
            children: List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 28),
                      ),
                    )),
          ),
        ],
      ),
    );
  }
}
