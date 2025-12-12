import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

class MenuDetailsDialog extends StatelessWidget {
  final MenuItem menu;

  const MenuDetailsDialog({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget imageSection() {
      final url = menu.imageUrl;
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
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                        : null,
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
          imageSection(),
          AppSpacing.verticalXs(context),

          // Name + Category chip
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: AppText.styledHeadingMedium(
                    context,
                    menu.name,
                    weight: AppFontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: AppText.styledBodyMedium(
                    context,
                    _prettyCategory(menu.category),
                    weight: AppFontWeight.semiBold,
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.verticalXs(context),

          // Description
          if (menu.description != null && menu.description!.isNotEmpty)
            Padding(
              padding: AppPadding.only(
                context,
                paddingType: Sizes.xs,
                bottom: true,
                left: true,
                right: true,
              ),
              child: AppText.styledBodyMedium(
                context,
                menu.description!,
              ),
            ),
        ],
      ),
    );
  }

  String _prettyCategory(MenuCategory category) {
    final raw = category.name; // enum name
    if (raw.isEmpty) return 'Other';
    return raw[0].toUpperCase() + raw.substring(1);
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
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(height: 8),
              Text(
                'No image available',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
