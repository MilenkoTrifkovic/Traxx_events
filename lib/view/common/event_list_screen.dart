import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/common/widgets/list_of_events.dart';
import 'package:traxx_wepapp/view/common/widgets/search_field.dart';
import 'package:traxx_wepapp/view/common/widgets/sort_events.dart';

/// A screen that displays a list of events for the host user.
///
/// This screen includes:
/// - A search field for filtering events
/// - A sort button for organizing events
/// - A scrollable list of event cards
/// - The behavior of the list items depends on the logged in user type (host/guest).
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Build the main layout with scrolling and padding
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and sort controls row
            Row(
              children: [
                // Search field that expands to fill available space
                Expanded(child: SearchField()),
                // Sort button with dropdown options
                SortEvents(),
              ],
            ),
            // Vertical spacing between controls and list
            AppSpacing.verticalMd(context),
            // List of event cards
            const ListOfEvents(),
          ],
        ),
      ),
    );
  }
}
