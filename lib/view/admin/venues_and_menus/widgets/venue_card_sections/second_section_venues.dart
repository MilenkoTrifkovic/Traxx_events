import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class SecondSection extends StatelessWidget {
  final Event event;

  const SecondSection({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              AppText.styledBodyMedium(
                context,
                'Location',
                weight: AppFontWeight.semiBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          AppText.styledBodyMedium(
            context,
            color: AppColors.textMuted,
            'Placeholder',
            weight: AppFontWeight.regular,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
