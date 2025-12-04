import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

class VenueDetailsDialog extends StatelessWidget {
  final Venue venue;

  const VenueDetailsDialog({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    Widget imageSection() {
      final url = venue.photoUrl;
      if (url != null && url.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _noImagePlaceholder(context),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  child: Center(
                    child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1)
                            : null),
                  ),
                );
              },
            ),
          ),
        );
      }

      return _noImagePlaceholder(context);
    }

    return AppDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image or placeholder
          imageSection(),

          AppSpacing.verticalXs(context),

          // Category
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                AppText.styledHeadingMedium(context, venue.name,
                    weight: AppFontWeight.bold, color: AppColors.black),
                AppSpacing.horizontalXs(context),
                // Chip(
                //   label: AppText.styledBodyMedium(
                //       context, _prettyCategory(venue.name.capitalize),
                //       weight: AppFontWeight.semiBold),
                // ),
              ],
            ),
          ),

          AppSpacing.verticalXs(context),

          // Description
          if (venue.description != null && venue.description!.isNotEmpty)
            Padding(
              padding: AppPadding.only  (context, paddingType: Sizes.xs, bottom: true, left: true, right: true),
              child: AppText.styledBodyMedium(
                context,
                venue.description!,
              ),
            ),
        ],
      ),
    );
  }

  String _prettyCategory(dynamic category) {
    try {
      final name = (category as Object).toString();
      // if enum has `name` property (MenuCategory), use it
      if (category is Enum) {
        final enumName = (category as dynamic).name as String?;
        if (enumName != null && enumName.isNotEmpty) {
          return _capitalize(enumName);
        }
      }
      return _capitalize(name);
    } catch (_) {
      return category.toString();
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _noImagePlaceholder(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported,
                  size: 48, color: Theme.of(context).hintColor),
              const SizedBox(height: 8),
              Text('No image available',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
