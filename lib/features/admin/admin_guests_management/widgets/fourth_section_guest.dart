import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class FourthSectionGuest extends StatelessWidget {
  final GuestModel guest;
  final VoidCallback? onPressed;
  final VoidCallback? onEdit;
  const FourthSectionGuest({
    super.key,
    required this.guest,
    required this.onPressed,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
            padding: AppPadding.right(context, paddingType: Sizes.xs),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    onEdit!();
                  },
                  icon: Icon(Icons.edit, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: () {
                    Dialogs.showConfirmationDialog(
                        context, 'Are you sure you want to delete this user?',
                        () {
                      if (onPressed != null) {
                        onPressed!();
                      }
                    });
                  },
                  icon: Icon(Icons.delete, color: AppColors.inputError),
                ),
              ],
            ))
      ],
    );
    // return Row(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   mainAxisAlignment: MainAxisAlignment.end,
    //   children: [
    //     Padding(
    //         padding: AppPadding.right(context, paddingType: Sizes.xs),
    //         child: IconButton(
    //           onPressed: onPressed,
    //           icon: Icon(Icons.delete, color: AppColors.inputError),
    //         ))
    //   ],
    // );
  }
}
