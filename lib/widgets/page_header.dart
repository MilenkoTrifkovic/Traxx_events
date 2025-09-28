import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// A consistent page header widget that displays a back button, centered title, and optional action.
/// Used across the app to provide a uniform navigation experience.
/// The header maintains symmetry by providing equal space for the back button and action.
class PageHeader extends StatelessWidget {
  /// Title text displayed in the center of the header
  final String title;

  const PageHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.vertical(context, paddingType: Sizes.xs).add(
        AppPadding.horizontal(context, paddingType: Sizes.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText.styledBodyLarge(
            context,
            title,
            weight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
