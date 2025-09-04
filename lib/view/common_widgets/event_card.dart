import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.sm),
          child: Row(
            children: [
              Container(
                child: event.coverImageDownloadUrl != null
                    ? Image.network(
                        event.coverImageDownloadUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
              Padding(
                padding: AppPadding.horizontal(context, paddingType: Sizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name
                    Row(
                      children: [
                        AppText.styledBodyLarge(
                          context,
                          event.name,
                          weight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.horizontalXs(context),
                        //status
                        AppText.styledBodySmall(
                            context, event.status.toLowerCase())
                      ],
                    ),
                    AppSpacing.verticalXs(context),
                    // Event date
                    AppText.styledBodyMedium(
                      context,
                      DateFormat('EEE, MMM d, y • h:mm a')
                          .format(event.startDateTime),
                    ),
                    AppSpacing.verticalXs(context),
                    // Status badge
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates a 48x48 placeholder widget with an event icon
  /// when the event has no cover image or if image loading fails
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.background(context),
      child: Center(
        child: Icon(
          Icons.event,
          size: 48,
          color: AppColors.onPrimaryContainer(context),
        ),
      ),
    );
  }
}
