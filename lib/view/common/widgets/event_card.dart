import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
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
  final Event event;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
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
            Expanded(child: FirstSection(event: event)),
            if (ScreenSize.isDesktop(context))
              Expanded(child: SecondSection(event: event)),
            if (ScreenSize.isDesktop(context))
              Expanded(child: ThirdSection(event: event)),
            if (ScreenSize.isDesktop(context))
              Expanded(child: FourthSection(event: event)),
          ],
        ),
      ),
    );
    // return Card(
    //   clipBehavior: Clip.antiAlias,
    //   elevation: 2,
    //   child: InkWell(
    //     onTap: onTap,
    //     child: Padding(
    //       padding: AppPadding.all(context, paddingType: Sizes.sm),
    //       child: Row(
    //         children: [
    //           Expanded(child: FirstSection(event: event)),
    //           Expanded(child: SecondSection(event: event)),
    //           Expanded(child: ThirdSection(event: event)),
    //           Expanded(child: FourthSection(event: event)),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
