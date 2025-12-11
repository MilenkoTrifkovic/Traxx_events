import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

class GuestPanelHeader extends StatelessWidget {
  // final String title;
  final bool isExpanded;
  final VoidCallback onTap;

  GuestPanelHeader({
    super.key,
    // required this.title,
    required this.isExpanded,
    required this.onTap,
  });
  final AdminGuestListController controller =
      Get.find<AdminGuestListController>();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.styledHeadingMedium(
              context,
              'Guest List',
              color: AppColors.primary,
            ),
            AppPrimaryButton(
                text: 'Add Guest',
                icon: Icons.add,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AddGuestPopup(controller: controller);
                      });
                }),
          ],
        ),
      ),
    );
  }
}
