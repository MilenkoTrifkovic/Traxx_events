import 'package:flutter/material.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/first_section_user_card.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/fourth_section_user_card.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class UserCard extends StatelessWidget {
  /// The user data to display in the card
  final UserModel user;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.borderInput,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      height: 88,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: FirstSectionUserCard(user: user)),
            // if (ScreenSize.isDesktop(context))
            //   Expanded(child: SecondSection(event: event)),
            // if (ScreenSize.isDesktop(context))
            //   Expanded(child: ThirdSection(event: event)),
            // if (ScreenSize.isDesktop(context))
            Expanded(
                child: FourthSectionUserCard(
                    user: user, onPressed: onDelete, onEdit: onEdit)),
          ],
        ),
      ),
    );
  }
}
