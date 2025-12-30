import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Empty state widget shown when there are no companions to add
class CompanionsInfoEmptyView extends StatelessWidget {
  final bool readOnly;
  final int? savedCount;
  final int? totalCount;
  final VoidCallback? onContinue;

  const CompanionsInfoEmptyView({
    super.key,
    this.readOnly = false,
    this.savedCount,
    this.totalCount,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      // In read-only mode, show a simple message
      return Center(
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              AppSpacing.verticalMd(context),
              AppText.styledHeadingMedium(
                context,
                'No Companions',
                weight: AppFontWeight.semiBold,
              ),
              AppSpacing.verticalSm(context),
              AppText.styledBodyMedium(
                context,
                'Preview mode: Companion information page',
              ),
            ],
          ),
        ),
      );
    }

    final saved = savedCount ?? 0;
    final total = totalCount ?? 0;

    return Center(
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            AppSpacing.verticalMd(context),
            AppText.styledHeadingMedium(
              context,
              saved > 0 ? 'All Companions Added' : 'No Companions',
              weight: AppFontWeight.semiBold,
            ),
            AppSpacing.verticalSm(context),
            AppText.styledBodyMedium(
              context,
              saved > 0
                  ? 'You have already added all $total companion${total > 1 ? 's' : ''} for this event.'
                  : 'You didn\'t select any companions for this event.',
            ),
            if (onContinue != null) ...[
              AppSpacing.verticalLg(context),
              // Continue button to proceed to next step
              SizedBox(
                width: 200,
                child: AppPrimaryButton(
                  onPressed: onContinue,
                  text: 'Continue',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

