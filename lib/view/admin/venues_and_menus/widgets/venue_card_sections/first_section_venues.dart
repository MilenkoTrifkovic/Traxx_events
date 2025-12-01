import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class FirstSectionVenues extends StatelessWidget {
  final Venue venue;

  const FirstSectionVenues({
    super.key,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(6), // 8 - 2 (border width) = 6
              child: venue.venueID == null
                  ? _buildPlaceholder(context)
                  // ? Image.network(
                  //     event.coverImageDownloadUrl!,
                  //     width: 44, // 48 - 4 (border width on both sides)
                  //     height: 44,
                  //     fit: BoxFit.cover,
                  //     errorBuilder: (context, error, stackTrace) =>
                  //         _buildPlaceholder(context),
                  // )
                  : _buildPlaceholder(context),
            ),
          ),
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.styledBodyLarge(
                  context,
                  venue.name,
                  weight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // AppSpacing.horizontalXxs(context),
                AppText.styledBodyMedium(
                  context,
                  color: AppColors.textMuted,
                  'Placeholder',
                  weight: AppFontWeight.semiBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                //status
                // AppText.styledBodySmall(
                //     context, event.status.toLowerCase())
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a 48x48 placeholder widget with a wine glass icon
  /// when the event has no cover image or if image loading fails
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.background(context),
      child: const Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 24,
          color: Colors.red,
        ),
      ),
    );
  }
}
