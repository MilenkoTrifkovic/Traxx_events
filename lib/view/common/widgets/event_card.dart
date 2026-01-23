import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card_sections/first_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card_sections/second_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card_sections/third_section.dart';
import 'package:traxx_wepapp/view/common/widgets/event_card_sections/fourth_section.dart';

/// A card widget that displays event information in a consistent format.
///
/// Features:
/// - Displays event cover image with fallback placeholder
/// - Shows event name, date, and status
class EventCard extends StatelessWidget {
  /// The event data to display in the card
  final Venue venue;
  final Event event;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.venue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.borderInput,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      height: 88,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(flex: 2, child: FirstSection(event: event)),
            if (ScreenSize.isDesktop(context))
              Expanded(
                  flex: 3, child: SecondSection(event: event, venue: venue)),
            if (ScreenSize.isDesktop(context) || ScreenSize.isTablet(context))
              Expanded(flex: 2, child: ThirdSection(event: event)),
            // if (ScreenSize.isDesktop(context))

            Expanded(flex: 1, child: FourthSection(event: event)),
          ],
        ),
      ),
    );
  }
}
