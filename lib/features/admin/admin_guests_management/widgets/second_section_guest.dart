import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class SecondSectionGuest extends StatelessWidget {
  final GuestModel guest;
  final VoidCallback? onPressed;
  const SecondSectionGuest({
    super.key,
    required this.guest,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
            padding: AppPadding.left(context, paddingType: Sizes.xs),
            child: AppText.styledBodyMedium(
              context,
             guest.email,
             weight: AppFontWeight.regular,
            ))
      ],
    );
  }
}
